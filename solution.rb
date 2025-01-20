require "digest"
require "thread"
require_relative "get_time.rb"

INPUT_TEXT = "hello world".freeze
CALCULATOR = Digest::SHA2.new(256)
REQUIREMENT = "000000".freeze

def vanil_solution
  i = 0

  loop do
    digest = CALCULATOR.hexdigest("#{INPUT_TEXT} #{i}")
    return i if digest.start_with?(REQUIREMENT) #digest[0...REQUIREMENT.size] == REQUIREMENT
    i += 1
  end
end

def threaded_solution(thread_count = 4)
  nonce_found = false
  result = nil
  mutex = Mutex.new

  threads = []

  thread_count.times do |i|
    threads << Thread.new do
      nonce = i
      step = thread_count
      calc = Digest::SHA2.new(256)

      loop do
        break if nonce_found

        data = "#{INPUT_TEXT} #{nonce}"
        hash = calc.hexdigest(data)

        if hash.start_with?(REQUIREMENT)
          mutex.synchronize do
            unless nonce_found
              nonce_found = true
              result = nonce
            end
          end

          break
        end

        nonce += step
      end
    end
  end

  threads.each(&:join)

  result
end

start_time = get_time
found = true ? threaded_solution(8) : vanil_solution
duration_ms = ((get_time - start_time) * 1000).round(3)

puts "(#{duration_ms}ms) #{found}: #{CALCULATOR.hexdigest("#{INPUT_TEXT} #{found}")}"
