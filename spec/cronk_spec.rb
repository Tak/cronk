# frozen_string_literal: true

ONE_SECOND_IN_DAYS = Rational(1, 86400)
TEN_MS_IN_DAYS = Rational(1, 8640000)

RSpec.describe Cronk do
  it "has a version number" do
    expect(Cronk::VERSION).not_to be nil
  end

  it "throws if interval is zero" do
    expect { Cronk::Cronk.new.schedule(nil, Rational(0,24)) }.to raise_error(ArgumentError)
  end

  it "throws if interval is negative" do
    expect { Cronk::Cronk.new.schedule(nil, Rational(-1,24)) }.to raise_error(ArgumentError)
  end

  it "runs and reschedules tasks" do
    cronk = Cronk::Cronk.new
    executed = 0
    cronk.schedule(DateTime.now + TEN_MS_IN_DAYS, TEN_MS_IN_DAYS) do
      executed += 1
    end

    # No tasks expired yet
    expect(executed).to eq(0)
    expect(cronk.run_tasks).to eq(0)
    expect(executed).to eq(0)

    # First expiration
    sleep(0.01)
    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(1)

    # First interval expiration
    sleep(0.01)
    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(2)
  end

  it "executes tasks with nil execution time on first poll" do
    cronk = Cronk::Cronk.new
    executed = 0
    cronk.schedule(nil, nil) do
      executed += 1
    end

    expect(executed).to eq(0)
    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(1)
  end

  it "reschedules interval-only tasks" do
    cronk = Cronk::Cronk.new
    executed = 0
    cronk.schedule(nil, TEN_MS_IN_DAYS) do
      executed += 1
    end

    expect(executed).to eq(0)
    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(1)
    sleep(0.01)

    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(2)
  end

  it "does not reschedule tasks with no interval" do
    cronk = Cronk::Cronk.new
    executed = 0
    cronk.schedule(DateTime.now) do
      executed += 1
    end

    expect(executed).to eq(0)
    expect(cronk.run_tasks).to eq(1)
    expect(executed).to eq(1)

    expect(cronk.instance_variable_get(:@queue).size).to eq(0) # Queue is empty now
    expect(cronk.run_tasks).to eq(0) # Running tasks should succeed, but have no effect
    expect(executed).to eq(1)
  end

  it "orders tasks by execution time" do
    cronk = Cronk::Cronk.new
    first = second = third = nil
    now = DateTime.now

    cronk.schedule(now + TEN_MS_IN_DAYS, nil) do
      second = DateTime.now
    end
    cronk.schedule(now + (2 * TEN_MS_IN_DAYS), nil) do
      third = DateTime.now
    end
    cronk.schedule(now, nil) do
      first = DateTime.now
    end

    verify_queue_order(cronk)
    sleep(0.2)
    expect(cronk.run_tasks).to eq(3)

    expect(third).to be >= second
    expect(second).to be >= first
  end

  it "orders correctly when rescheduling" do
    cronk = Cronk::Cronk.new
    first_then_third = second_then_first = third_then_second = nil
    now = DateTime.now

    cronk.schedule(now + TEN_MS_IN_DAYS, TEN_MS_IN_DAYS) do
      second_then_first = DateTime.now
    end
    cronk.schedule(now + (2 * TEN_MS_IN_DAYS), ONE_SECOND_IN_DAYS) do
      third_then_second = DateTime.now
    end
    cronk.schedule(now, 2 * ONE_SECOND_IN_DAYS) do
      first_then_third = DateTime.now
    end

    verify_queue_order(cronk)
    sleep(0.2)
    expect(cronk.run_tasks).to eq(3)
    expect(third_then_second).to be >= second_then_first
    expect(second_then_first).to be >= first_then_third
    verify_queue_order(cronk)
  end

  def verify_queue_order(cronk)
    cronk.instance_variable_get(:@queue).each_cons(2) do |pair|
      expect(pair[1].first).to be >= pair[0].first
    end
  end
end
