def get_time
  # via_time
  via_process
end

def via_time
  Time.now
end

def via_process
  Process.clock_gettime(Process::CLOCK_MONOTONIC)
end
