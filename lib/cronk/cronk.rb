require "date"

require_relative "task"

module Cronk
  # Class for periodically performing tasks
  class Cronk
    def initialize
      @queue = []
    end

    # Schedule a task
    # @param first The first time the task should be executed (nil for immediately)
    # @param interval The repeat interval for the task (nil for one-time-only tasks)
    # @param block A block that will be invoked without arguments when the task executes
    def schedule(first, interval = nil, &block)
      if interval
        raise ArgumentError.new("Interval must be nonzero") if interval == 0
        raise ArgumentError.new("Interval must be positive") if interval < 0
      end

      insert_task(Task.new(first || DateTime.now, interval, &block))
    end

    # Insert a task into the queue at the appropriate place
    # @param task The task to insert
    def insert_task(task)
      if @queue.empty?
        @queue << task
      else
        index = @queue.bsearch_index { |queued_task| task.first > queued_task.first } || -1
        @queue.insert(index + 1, task)
      end
    end
    private :insert_task

    # Run all tasks whose execution time is in the past
    # Executed tasks are rescheduled or removed from the queue
    def run_tasks
      now = DateTime.now
      last_executed_index = -1

      @queue.each_with_index do |task, index|
        break unless now > task.first

        run_task(task)
        last_executed_index = index
      end

      reschedule_tasks(@queue.slice!(0..last_executed_index)) if last_executed_index >= 0
      last_executed_index + 1
    end

    def reschedule_tasks(tasks)
      tasks.select { |task| task.interval }.each do |task|
        task.first += task.interval while task.first < DateTime.now
        insert_task(task)
      end
    end
    private :reschedule_tasks

    # Run a single task
    # If the task has a scheduling interval, reschedule it
    # @param task The task to run
    def run_task(task)
      task.block&.call
    end
    private :run_task
  end
end
