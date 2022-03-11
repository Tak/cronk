module Cronk
  class Task
    attr_accessor :first
    attr_reader :interval
    attr_reader :block

    def initialize(first, interval, &block)
      @first = first
      @interval = interval
      @block = block
    end
  end
end
