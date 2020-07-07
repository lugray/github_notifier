module GithubNotifier
  class Each < Array
    class << self
      def [](*items)
        new(*items)
      end
    end

    def initialize(*items)
      replace(items)
    end

    def ===(other)
      other.size == size && zip(other).all? { |s, o| s === o }
    end
  end

  class ANY
    def self.===(other)
      true
    end
  end
end
