require "date"

require_relative "task"

module Cronk
  class Cronk
    def initialize
      @queue = []
    end

    def schedule(first, interval = nil, &block)
      if interval
        raise ArgumentError.new("Interval must be nonzero") if interval == 0
        raise ArgumentError.new("Interval must be positive") if interval < 0
      end

      insert_task(Task.new(first || DateTime.now, interval, &block))
    end

    def insert_task(task)
      index = @queue.bsearch_index { |queued_task| task.first > queued_task.first }
      if index
        @queue.insert(index, task)
      else
        @queue << task
      end
    end
    private :insert_task

    def run_tasks
      now = DateTime.now
      last_executed_index = -1

      @queue.each_with_index do |task, index|
        break unless now > task.first

        run_task(task)
        last_executed_index = index
      end

      @queue.slice!(last_executed_index) if last_executed_index >= 0
      last_executed_index + 1
    end

    def run_task(task)
      task.block&.call

      return unless task.interval

      while task.first < DateTime.now
        task.first += task.interval
      end
      insert_task(task)
    end
    private :run_task
  end
end
