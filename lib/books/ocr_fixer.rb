#!/usr/bin/env ruby
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "ruby-openai"
end

require "openai"
require "json"
require "tempfile"
require "fileutils"

# Configuration
BASE_URL = "http://10.0.0.202:8080".freeze
MODEL_NAME = "Qwen3.6-27B-Q3_K_M.gguf".freeze
MIN_CHUNK_SIZE = 1200 # Original chunk size
CONTEXT_PARAGRAPHS = 2 # Number of previous paragraphs to include as context
BATCH_SIZE = 4 # Number of chunks to correct before prompting the user

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
    # Explicitly configure reasoning_format: "none" to bypass the default
    # llama-server deepseek-parser. This avoids silent truncation issues.
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
      reasoning = message&.dig("reasoning_content")
      if reasoning && !reasoning.empty?
        STDERR.puts colorize("\nAPI Error: Model filled 'reasoning_content' but left 'content' empty.\n" \
                             "Ensure llama-server was started with --reasoning-format none", 31)
      else
        STDERR.puts colorize("\nAPI Error: Unexpected response format or empty content - #{response.inspect}", 31)
      end
      nil # Return nil on failure to avoid saving errors to your output document
    else
      # Extract only the corrected text by parsing out the raw <think> block
      if content =~ /<\/think>/
        content.split(/<\/think>\s*/, 2).last.strip
      elsif content =~ /<think>/
        # Fallback if the <think> tag was opened but the closing tag got truncated
        content.gsub(/<think>.*\z/m, "").strip
      else
        content.strip
      end
    end
  rescue Faraday::ConnectionFailed => e
    STDERR.puts colorize("\nConnection Error: Connection refused at #{BASE_URL}. Is llama-server running?", 31)
    nil
  rescue StandardError => e
    STDERR.puts colorize("\nError: #{e.class} - #{e.message}", 31)
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
state = { "current_index" => 0, "last_fixed_paragraphs" => [] }
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
# Split by 2 or more newlines, stripping whitespace
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
# add any remaining tail
paragraphs << current_chunk.join("\n\n") unless current_chunk.empty?

puts "Total smart-chunks found: #{paragraphs.length}"

idx = state["current_index"]

# Helper function to sequentially call the LLM for a batch of paragraphs
def generate_batch_predictions(batch, start_idx, paragraphs_count, state_context_history)
  predictions = []
  failed = false

  # Initialize the context history for this specific batch's sequence
  current_context = state_context_history.last(CONTEXT_PARAGRAPHS).join("\n\n")

  batch.each_with_index do |para, i|
    chunk_num = start_idx + 1 + i
    print "Generating correction for Chunk #{chunk_num} / #{paragraphs_count}...\r"

    pred = call_llm(current_context, para)
    if pred.nil?
      failed = true
      break
    end

    predictions << pred
    # Update the sliding context window for the next paragraph in the batch
    temp_history = state_context_history + predictions
    current_context = temp_history.last(CONTEXT_PARAGRAPHS).join("\n\n")
  end
  print "                                                                \r" # Clear line

  failed ? nil : predictions.join("\n\n")
end

# Main Interactive Loop
while idx < paragraphs.length
  batch = paragraphs[idx, BATCH_SIZE]
  batch_size = batch.length

  puts "\n" + "="*80
  puts colorize("Paragraphs #{idx + 1} - #{idx + batch_size} / #{paragraphs.length}", 36)
  puts "-"*80

  # Display all raw chunks in this batch
  batch.each_with_index do |p, i|
    puts colorize("--- Chunk #{idx + 1 + i} ---", 33)
    puts colorize(p, 31) # Red for original raw OCR
    puts ""
  end
  puts "="*80

  # Generate predictions for all paragraphs in the batch
  prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["last_fixed_paragraphs"])

  loop do
    # Protect from writing terminal/error strings if an API call fails
    if prediction.nil?
      puts colorize("\nPrediction generation failed due to an API or connection error.", 31)
      print "Action: [" + colorize("R", 34) + "]etry, [" + colorize("Q", 31) + "]uit: "
      choice = $stdin.gets.to_s.chomp.downcase

      case choice
      when "r"
        puts "Retrying the batch..."
        prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["last_fixed_paragraphs"])
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

    puts "\n" + colorize("=== PREDICTION (Batch of #{batch_size}) ===", 32)
    puts colorize(prediction, 32) # Green for combined prediction
    puts colorize("=========================================", 32)

    print "\nAction: [" + colorize("A", 32) + "]ccept, [" + colorize("E", 33) + "]dit, [" + colorize("R", 34) + "]etry, [" + colorize("Q", 31) + "]uit: "
    choice = $stdin.gets.to_s.chomp.downcase

    case choice
    when "a", "" # Default to accept on empty enter
      File.open(output_file, "a") do |f|
        f.puts prediction
        f.puts "\n\n"
      end

      # Split your accepted (and potentially edited) output into individual
      # paragraphs to cleanly preserve the running context history
      accepted_paragraphs = prediction.split(/\n\s*\n/).map(&:strip).reject(&:empty?)

      # Update state
      state["current_index"] = idx + batch_size
      state["last_fixed_paragraphs"] += accepted_paragraphs
      state["last_fixed_paragraphs"] = state["last_fixed_paragraphs"].last(CONTEXT_PARAGRAPHS)

      File.write(state_file, JSON.pretty_generate(state))

      idx += batch_size # Advance outer loop index
      break # Exit inner loop and move to the next batch

    when "e"
      prediction = edit_in_terminal(prediction)
      # Loop repeats, printing the edited 4-paragraph text so you can review/accept

    when "r"
      puts "Retrying the batch..."
      prediction = generate_batch_predictions(batch, idx, paragraphs.length, state["last_fixed_paragraphs"])

    when "q"
      puts "\nProgress saved to #{state_file}."
      puts "Output so far saved to #{output_file}."
      puts "Exiting."
      exit 0

    else
      puts "Invalid choice. Please enter A, E, R, or Q."
    end
  end
end

puts "\n🎉 Processing complete! Finished file saved to #{output_file}"
# Clean up the progress file when completely done
File.delete(state_file) if File.exist?(state_file)
