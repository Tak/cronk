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
end
