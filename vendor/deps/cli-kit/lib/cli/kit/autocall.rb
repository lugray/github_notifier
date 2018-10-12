require 'cli/kit'

module CLI
  module Kit
    module Autocall
      def autocall(const, &block)
        @autocalls ||= {}
        @autocalls[const] = block
      end

      def const_missing(const)
        block = begin
          autocalls.fetch(const) { super }
        end
        const_set(const, block.call)
      end

      private

      def autocalls
        @autocalls ||= {}
      end
    end
  end
end
