require 'ruby_llm/message'
require 'ruby_llm/thinking'
require 'ruby_llm/providers/openai'
require 'ruby_llm/providers/openrouter/chat'
require 'ruby_llm/providers/openrouter/models'
require 'ruby_llm/providers/openrouter/streaming'
require 'ruby_llm/providers/openrouter/images'

module XAeonAgents
  # Collection of providers for ai-agents
  module Providers
    # Cline API integration.
    class Cline < RubyLLM::Providers::OpenAI
      # @return [String] The base API URL
      def api_base
        @config.cline_api_base || 'https://api.cline.bot/api/v1'
      end

      # @return [Hash{String => String}] HTTP headers to add to the queries
      def headers
        {
          'Authorization' => "Bearer #{@config.cline_api_key}"
        }
      end

      # Parses the completion response from the Cline API into a [RubyLLM::Message].
      #
      # Handles empty responses, API errors, message extraction, content/thinking parsing,
      # token usage tracking (including cached and reasoning tokens), and tool calls.
      #
      # @param response [Faraday::Response] The raw HTTP response from the Cline API.
      # @return [RubyLLM::Message, nil] The parsed message, or nil if the response body is empty
      #   or no message data is present.
      def parse_completion_response(response)
        data = response.body
        return if data.empty?

        raise Error.new(response, data.dig('error')) if data.dig('error')

        message_data = data.dig('data', 'choices', 0, 'message')
        return unless message_data

        usage = data.dig('data', 'usage') || {}
        cached_tokens = usage.dig('prompt_tokens_details', 'cached_tokens')
        thinking_tokens = usage.dig('completion_tokens_details', 'reasoning_tokens')
        content, thinking_from_blocks = extract_content_and_thinking(message_data['content'])
        thinking_text = thinking_from_blocks || extract_thinking_text(message_data)
        thinking_signature = extract_thinking_signature(message_data)

        RubyLLM::Message.new(
          role: :assistant,
          content: content,
          thinking: RubyLLM::Thinking.build(text: thinking_text, signature: thinking_signature),
          tool_calls: parse_tool_calls(message_data['tool_calls']),
          input_tokens: usage['prompt_tokens'],
          output_tokens: usage['completion_tokens'],
          cached_tokens: cached_tokens,
          cache_creation_tokens: 0,
          thinking_tokens: thinking_tokens,
          model_id: data.dig('data', 'model'),
          raw: response
        )
      end

      private

      class << self

        # @return [Array<Symbol>] The required configuration keys for the Cline provider.
        def configuration_requirements
          %i[cline_api_base cline_api_key]
        end

        # @return [Array<Symbol>] The available configuration keys for the Cline provider.
        def configuration_options
          %i[cline_api_base cline_api_key]
        end
      end
    end
  end
end
