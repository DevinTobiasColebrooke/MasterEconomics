#!/usr/bin/env ruby
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "ruby-openai"
  gem "clipboard" # Reads/Writes Windows/host clipboard natively
end

require "openai"
require "json"
require "tempfile"
require "fileutils"
require "clipboard"

# Configuration
BASE_URL = "http://10.0.0.202:8080".freeze
MODEL_NAME = "Qwen3.6-27B-Q3_K_M.gguf".freeze
MIN_CHUNK_SIZE = 1200 # Standard chunk size
CONTEXT_PARAGRAPHS = 2 # Context paragraphs for the local LLM

BATCH_SIZE = 4 # Local LLM mode batch size
MANUAL_BATCH_SIZE = 10 # Safer batch size to prevent web LLM laziness/truncation (approx 24,000 chars)

OpenAI.configure do |config|
  config.access_token = "dummy"
  config.uri_base = BASE_URL
end

# Use a custom Faraday block to strictly enforce a huge timeout
LLM_CLIENT = OpenAI::Client.new do |f|
  f.options.timeout = 1800      # 30 minutes read timeout
  f.options.open_timeout = 1800 # 30 minutes connection timeout
end

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

# Helper to write to clipboard, optimized for WSL
def write_clipboard(text)
  is_wsl = File.read("/proc/version").downcase.include?("microsoft") rescue false

  if is_wsl
    IO.popen("clip.exe", "w") { |io| io.write(text.encode("UTF-16LE")) }
    true
  else
    Clipboard.copy(text)
    true
  end
rescue => e
  false
end

# Helper to read from clipboard, optimized for WSL
def read_clipboard
  is_wsl = File.read("/proc/version").downcase.include?("microsoft") rescue false

  if is_wsl
    `powershell.exe -NoProfile -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard"`.gsub(/\r\n/, "\n").strip
  else
    Clipboard.paste
  end
rescue => e
  nil
end

# Rebuild the clean output file from the current history state
def rebuild_output_file(output_file, history)
  File.open(output_file, "w") do |f|
    history.each do |h|
      f.puts h["text"]
      f.puts "\n\n"
    end
  end
end

# Extract running context from the last few blocks in the history list
def get_running_context(history, count)
  all_paragraphs = history.map { |h| h["text"] }.join("\n\n").split(/\n\s*\n/).map(&:strip).reject(&:empty?)
  all_paragraphs.last(count).join("\n\n")
end

def call_llm(context, messy_text)
  system_prompt = <<~PROMPT
    You are an automated OCR correction script. You receive raw, broken OCR text and output the exact same text with typos and formatting fixed.
    You do NOT reason, you do NOT think, and you do NOT explain.
    You immediately return the corrected text.
  PROMPT

  user_prompt = ""
  if context && !context.empty?
    user_prompt += "Here is the context (the previously corrected text) to help you understand the flow:\n#{context}\n\n"
  end
  user_prompt += "Now, fix the following text and output ONLY the fixed text:\n#{messy_text}"

  messages = [
    { role: "system", content: system_prompt },
    { role: "user", content: user_prompt }
  ]

  begin
    response = LLM_CLIENT.chat(
      parameters: {
        model: MODEL_NAME,
        messages: messages,
        temperature: 0.1,
        max_tokens: 8192,
        reasoning_format: "none"
      }
    )

    message = response.dig("choices", 0, "message")
    content = message&.dig("content")

    if content.nil? || content.empty?
      nil
    else
      if content =~ /<\/think>/
        content.split(/<\/think>\s*/, 2).last.strip
      elsif content =~ /<think>/
        content.gsub(/<think>.*\z/m, "").strip
      else
        content.strip
      end
    end
  rescue StandardError => e
    nil
  end
end

def edit_in_terminal(text)
  editor = ENV["EDITOR"] || "nano"
  Tempfile.create([ "ocr_fix", ".md" ]) do |f|
    f.write(text)
    f.flush
    system("#{editor} #{f.path}")
    File.read(f.path).strip
  end
end

# CLI Argument Parsing
if ARGV.empty?
  puts "Usage: ruby ocr_fixer.rb <path_to_markdown_file>"
  exit 1
end

input_file = ARGV[0]
unless File.exist?(input_file)
  puts "Error: File '#{input_file}' not found."
  exit 1
end

# Setup paths and state
base_name = File.basename(input_file, ".*")
dir_name = File.dirname(input_file)
output_file = File.join(dir_name, "#{base_name}_fixed.md")
state_file = File.join(dir_name, ".#{base_name}.progress.json")

# Load state
state = { "current_index" => 0, "history" => [] }
if File.exist?(state_file)
  begin
    state = JSON.parse(File.read(state_file))
    puts colorize("Resuming from paragraph #{state['current_index']}...", 33)
  rescue JSON::ParserError
    puts "Warning: state file corrupted. Starting from scratch."
  end
end

# Read and chunk the document
source_text = File.read(input_file)
raw_paragraphs = source_text.split(/\n\s*\n/).map(&:strip).reject(&:empty?)

paragraphs = []
current_chunk = []
current_length = 0

raw_paragraphs.each do |para|
  current_chunk << para
  current_length += para.length

  if current_length >= MIN_CHUNK_SIZE
    paragraphs << current_chunk.join("\n\n")
    current_chunk = []
    current_length = 0
  end
end
paragraphs << current_chunk.join("\n\n") unless current_chunk.empty?

puts "Total smart-chunks found: #{paragraphs.length}"

# Reconstruct history dynamically if progress file doesn't track it
if state["history"].nil? || state["history"].empty? || state["history"].first.is_a?(String)
  puts colorize("Upgrading progress file to robust range-based chunk history...", 34)
  raw_history_strings = []

  if state["history"]&.first.is_a?(String)
    raw_history_strings = state["history"]
  elsif File.exist?(output_file)
    raw_history_strings = File.read(output_file).split(/\n\s*\n/).map(&:strip).reject(&:empty?)
  end

  new_history = []
  raw_history_strings.each_with_index do |block, i|
    new_history << {
      "start_index" => i + 1,
      "end_index" => i + 1,
      "text" => block
    }
  end

  state["history"] = new_history
  state["current_index"] = new_history.empty? ? 0 : new_history.last["end_index"]
  File.write(state_file, JSON.generate(state))
  puts colorize("Successfully migrated #{new_history.length} chunks to the new range-based format!", 32)
end

idx = state["current_index"]

# Helper function to sequentially call the LLM for a batch of paragraphs
def generate_batch_predictions(batch, start_idx, paragraphs_count, state_context_history)
  predictions = []
  failed = false
  current_context = get_running_context(state_context_history, CONTEXT_PARAGRAPHS)

  batch.each_with_index do |para, i|
    chunk_num = start_idx + 1 + i
    print "Generating correction for Chunk #{chunk_num} / #{paragraphs_count}...\r"

    pred = call_llm(current_context, para)
    if pred.nil?
      failed = true
      break
    end

    predictions << pred
    temp_history = state_context_history + [ { "text" => pred } ]
    current_context = get_running_context(temp_history, CONTEXT_PARAGRAPHS)
  end
  print "                                                                \r"

  failed ? nil : predictions.join("\n\n")
end

# Troubleshooting Core Routine
def run_troubleshooter(paragraphs, state, output_file, state_file)
  puts "\n" + "="*80
  puts colorize("=== CHUNK TROUBLESHOOTING TOOL ===", 35)
  print "Enter chunk index (e.g. 56) or range (e.g. 56-60) to inspect: "
  input = $stdin.gets.to_s.chomp.strip

  if input =~ /^(\d+)$/
    target_start = $1.to_i
    target_end = target_start
  elsif input =~ /^(\d+)\s*-\s*(\d+)$/
    target_start = $1.to_i
    target_end = $2.to_i
  else
    puts colorize("Error: Invalid format. Enter a single number (56) or a range (56-60).", 31)
    return nil
  end

  if target_start < 1 || target_end > paragraphs.length || target_start > target_end
    puts colorize("Error: Chunk range out of bounds.", 31)
    return nil
  end

  target_size = target_end - target_start + 1
  target_batch = paragraphs[(target_start - 1)..(target_end - 1)]
  target_raw_text = target_batch.join("\n\n")

  puts "\n" + "-"*80
  puts colorize("--- ORIGINAL RAW OCR TEXT (Chunks #{target_start} - #{target_end}) ---", 33)
  puts colorize(target_raw_text, 31)
  puts "-"*80
  puts colorize("--- CURRENT SAVED CORRECTIONS ---", 32)

  # Find all existing history blocks that overlap with this range
  overlapping_blocks = state["history"].select do |h|
    (h["start_index"]..h["end_index"]).to_a.any? { |chunk_num| chunk_num >= target_start && chunk_num <= target_end }
  end
  saved_text = overlapping_blocks.empty? ? nil : overlapping_blocks.map { |h| h["text"] }.join("\n\n")

  if saved_text
    puts colorize(saved_text, 32)
  else
    puts colorize("[No saved correction exists yet for this range]", 33)
  end
  puts "="*80

  print "\nOptions: [" + colorize("E", 33) + "]dit in-place, [" + colorize("R", 32) + "]edo range, [" + colorize("W", 31) + "]indback (truncate and resume progress from here), [" + colorize("C", 34) + "]ancel: "
  ts_choice = $stdin.gets.to_s.chomp.downcase

  case ts_choice
  when "e"
    if saved_text.nil?
      puts colorize("Error: You cannot edit a chunk that hasn't been processed yet. Use Redo Range or Windback instead.", 31)
    else
      edited_block = edit_in_terminal(saved_text)

      # For simplicity, we merge the overlapping blocks into a single consolidated edited block
      state["history"].reject! { |h| overlapping_blocks.include?(h) }
      state["history"] << {
        "start_index" => target_start,
        "end_index" => target_end,
        "text" => edited_block
      }
      state["history"].sort_by! { |h| h["start_index"] }

      rebuild_output_file(output_file, state["history"])
      File.write(state_file, JSON.generate(state))
      puts colorize("\nSuccess: Chunks #{target_start}-#{target_end} edited in-place and file updated!", 32)
    end
  when "r"
    # Redo Range through either local model or clipboard
    print "\nRedo Mode: Press " + colorize("Enter", 32) + " to run local LLM, or type [" + colorize("M", 33) + "]anual for external copy-paste: "
    redo_mode = $stdin.gets.to_s.chomp.downcase

    redo_prediction = nil
    if redo_mode == "m"
      backup_file = "raw_batch.md"
      File.write(backup_file, target_raw_text)
      copied_successfully = write_clipboard(target_raw_text)

      if copied_successfully
        puts colorize("\nSUCCESS: Chunks automatically copied to Windows clipboard!", 32)
      else
        puts colorize("\nCLIPBOARD NOTE: System clipboard unavailable. Raw text written to '#{backup_file}'.", 31)
      end

      puts "1. Paste the raw text into your external model."
      puts "2. Copy the corrected output."
      print "3. Return here and press " + colorize("[Enter]", 32) + " to import: "
      $stdin.gets

      clipboard_text = read_clipboard
      if clipboard_text && !clipboard_text.empty? && clipboard_text != target_raw_text
        redo_prediction = clipboard_text
      else
        puts colorize("\nWarning: Clipboard was empty or unchanged.", 31)
      end
    else
      # Sequentially run the local LLM using context up to the redo start point
      history_up_to_target = state["history"].select { |h| h["end_index"] < target_start }
      redo_prediction = generate_batch_predictions(target_batch, target_start - 1, paragraphs.length, history_up_to_target)
    end

    if redo_prediction
      puts "\n" + colorize("=== CURRENT REDO PREDICTION ===", 32)
      puts colorize(redo_prediction, 32)
      puts colorize("===============================", 32)

      print "\nAction: [" + colorize("A", 32) + "]ccept redo, [" + colorize("E", 33) + "]dit, [" + colorize("C", 34) + "]ancel: "
      redo_action = $stdin.gets.to_s.chomp.downcase

      if redo_action == "e"
        redo_prediction = edit_in_terminal(redo_prediction)
        redo_action = "a" # default to accept edited
      end

      if redo_action == "a" || redo_action == ""
        # Remove old overlapping blocks, insert sorted new block, and rebuild file
        state["history"].reject! { |h| overlapping_blocks.include?(h) }
        state["history"] << {
          "start_index" => target_start,
          "end_index" => target_end,
          "text" => redo_prediction
        }
        state["history"].sort_by! { |h| h["start_index"] }

        rebuild_output_file(output_file, state["history"])
        File.write(state_file, JSON.generate(state))
        File.delete("raw_batch.md") if File.exist?("raw_batch.md")
        puts colorize("\nSuccess: Redo accepted and output updated!", 32)
      end
    end
  when "w"
    # Windback: slice history back to the target chunk and resume standard loop from there
    state["history"].reject! { |h| h["start_index"] >= target_start }
    state["current_index"] = target_start - 1
    rebuild_output_file(output_file, state["history"])
    File.write(state_file, JSON.generate(state))

    puts colorize("\nWindback complete! Output file truncated. Resuming from chunk #{target_start}...", 33)
    return target_start - 1 # Return new index to transition loop
  else
    puts "Troubleshooting canceled."
  end
  nil
end

# === STARTUP MENU ===
loop do
  puts "\n" + "="*80
  puts colorize("=== OCR FIXER STARTUP MENU ===", 35)
  puts "Current Progress: Paragraph #{idx + 1} / #{paragraphs.length}"
  puts "1. Continue with standard progress (Resume)"
  puts "2. Troubleshoot (Inspect / edit / redo / windback past chunks)"
  puts "3. Quit"
  print "Select option [1-3] (Default is 1): "
  startup_choice = $stdin.gets.to_s.chomp.downcase

  if startup_choice == "2"
    new_idx = run_troubleshooter(paragraphs, state, output_file, state_file)
    if new_idx
      idx = new_idx
      break # Exit startup menu and proceed directly to main loop on rewound index
    end
  elsif startup_choice == "3" || startup_choice == "q"
    puts "Exiting."
    exit 0
  else
    break # Default: Exit startup menu and proceed to standard progress loop
  end
end

# Main Interactive Loop
while idx < paragraphs.length
  puts "\n" + "="*80
  puts colorize("Paragraph #{idx + 1} / #{paragraphs.length}", 36)
  puts "="*80

  # Ask the user up front which mode they want, dynamically determining batch size
  print "Press " + colorize("Enter", 32) + " for local LLM (4 chunks), or type [" + colorize("M", 33) + "]anual for external copy-paste (20 chunks): "
  mode_choice = $stdin.gets.to_s.chomp.downcase

  current_batch_size = (mode_choice == "m") ? MANUAL_BATCH_SIZE : BATCH_SIZE
  batch = paragraphs[idx, current_batch_size]
  batch_size = batch.length

  raw_text = batch.join("\n\n")

  prediction = nil
  if mode_choice == "m"
    puts "\n" + "="*80
    puts colorize("Paragraphs #{idx + 1} - #{idx + batch_size} / #{paragraphs.length} [MANUAL MODE]", 36)
    puts "="*80

    backup_file = "raw_batch.md"
    File.write(backup_file, raw_text)

    copied_successfully = write_clipboard(raw_text)

    if copied_successfully
      puts colorize("SUCCESS: #{batch_size} raw chunks (~#{raw_text.length} characters) automatically copied to Windows clipboard!", 32)
      puts colorize("FAIL-SAFE: Written to workspace file '#{backup_file}' (visible in VS Code sidebar).", 34)
    else
      puts colorize("CLIPBOARD NOTE: System clipboard unavailable over headless connection.", 31)
      puts colorize("Pasted text into workspace file: '#{backup_file}' (open in VS Code sidebar).", 33)
    end

    puts ""
    puts "1. Paste the clipboard contents OR copy directly from the '#{backup_file}' tab in VS Code."
    puts "2. Paste it into your external model (Claude, Gemini, etc.)."
    puts "3. Copy the cleaned output from the browser."
    print "4. Return to VS Code and press " + colorize("[Enter]", 32) + " to import your clipboard output: "
    $stdin.gets

    clipboard_text = read_clipboard
    if clipboard_text && !clipboard_text.empty? && clipboard_text != raw_text
      prediction = clipboard_text
      puts colorize("\nSuccessfully grabbed corrected text from system clipboard!", 32)
    else
      puts colorize("\nWarning: Clipboard was empty, unchanged, or could not be read.", 31)
      puts colorize("Opening manual editor containing raw text template...", 33)
      prediction = raw_text
    end
  else
    puts "\n" + "="*80
    puts colorize("Paragraphs #{idx + 1} - #{idx + batch_size} / #{paragraphs.length}", 36)
    puts "-"*80
    batch.each_with_index do |p, i|
      puts colorize("--- Chunk #{idx + 1 + i} ---", 33)
      puts colorize(p, 31)
      puts ""
    end
    puts "="*80

    prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["history"])
  end

  loop do
    if prediction.nil?
      puts colorize("\nPrediction generation failed due to an API or connection error.", 31)
      print "Action: [" + colorize("R", 34) + "]etry, [" + colorize("Q", 31) + "]uit: "
      choice = $stdin.gets.to_s.chomp.downcase

      case choice
      when "r"
        puts "Retrying the batch..."
        prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["history"])
      when "q"
        puts "\nProgress saved to #{state_file}."
        puts "Output so far saved to #{output_file}."
        puts "Exiting."
        exit 0
      else
        puts "Invalid choice. Please enter R or Q."
      end
      next
    end

    # Print the prediction for verification
    puts "\n" + colorize("=== CURRENT PREDICTION (Batch of #{batch_size}) ===", 32)
    puts colorize(prediction, 32)
    puts colorize("=================================================", 32)

    print "\nAction: [" + colorize("A", 32) + "]ccept, [" + colorize("E", 33) + "]dit, [" + colorize("T", 35) + "]roubleshoot, [" + colorize("R", 34) + "]etry, [" + colorize("Q", 31) + "]uit: "
    choice = $stdin.gets.to_s.chomp.downcase

    case choice
    when "a", "" # Default to accept on empty enter
      File.open(output_file, "a") do |f|
        f.puts prediction
        f.puts "\n\n"
      end

      # Clean up backup file when accepted
      File.delete("raw_batch.md") if File.exist?("raw_batch.md")

      # Update state
      state["current_index"] = idx + batch_size
      state["history"] << {
        "start_index" => idx + 1,
        "end_index" => idx + batch_size,
        "text" => prediction
      }

      File.write(state_file, JSON.generate(state))

      idx += batch_size # Advance index by actual batch size
      break

    when "e"
      prediction = edit_in_terminal(prediction)

    when "t"
      new_idx = run_troubleshooter(paragraphs, state, output_file, state_file)
      if new_idx
        idx = new_idx
        break # Break out of inner loop to refresh main loop with new index
      end

    when "r"
      if mode_choice == "m"
        print "Type [" + colorize("C", 32) + "]lipboard to re-grab, or [" + colorize("L", 34) + "]ocal to run local LLM: "
        retry_choice = $stdin.gets.to_s.chomp.downcase

        if retry_choice == "l"
          puts "Generating predictions using local LLM... (This may take a while for #{batch_size} chunks)"
          mode_choice = "local"
          prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["history"])
        else
          print colorize("\nCopy the corrected text, then press [Enter] to re-grab...", 33)
          $stdin.gets
          clipboard_text = read_clipboard
          if clipboard_text && !clipboard_text.empty?
            prediction = clipboard_text
            puts colorize("\nSuccessfully grabbed text from system clipboard!", 32)
          end
        end
      else
        puts "Retrying the batch..."
        prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["history"])
      end

    when "q"
      puts "\nProgress saved to #{state_file}."
      puts "Output so far saved to #{output_file}."
      puts "Exiting."
      exit 0

    else
      puts "Invalid choice. Please enter A, E, T, R, or Q."
    end
  end
end

puts "\n🎉 Processing complete! Finished file saved to #{output_file}"
File.delete(state_file) if File.exist?(state_file)
