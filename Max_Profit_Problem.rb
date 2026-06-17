BUILDINGS = [
  { name: "T", time: 5, earn: 1500 },
  { name: "P", time: 4, earn: 1000 },
  { name: "C", time: 10, earn: 2000 }
]

def optimize(n)
  dp = Array.new(n + 1, -Float::INFINITY)
  paths = Array.new(n + 1) { [] }

  dp[0] = 0
  paths[0] = [
    { "T" => 0, "P" => 0, "C" => 0 }
  ]

  (0..n).each do |time_used|
    next if dp[time_used] == -Float::INFINITY

    BUILDINGS.each do |building|
      new_time = time_used + building[:time]
      next if new_time > n

      remaining_time = n - new_time

      # Ignore buildings that never become operational
      next if remaining_time <= 0

      profit = building[:earn] * remaining_time
      candidate_profit = dp[time_used] + profit

      new_paths = paths[time_used].map do |path|
        updated = path.dup
        updated[building[:name]] += 1
        updated
      end

      if candidate_profit > dp[new_time]
        dp[new_time] = candidate_profit
        paths[new_time] = new_paths

      elsif candidate_profit == dp[new_time]
        paths[new_time].concat(new_paths)
      end
    end
  end

  max_profit = dp.max

  best_solutions = []

  (0..n).each do |t|
    next unless dp[t] == max_profit

    best_solutions.concat(paths[t])
  end

  best_solutions.uniq!

  [max_profit, best_solutions]
end

print "Enter Time Units: "
n = gets.to_i

profit, solutions = optimize(n)

puts "\nEarnings: $#{profit}"
puts "Solutions"

solutions.each_with_index do |solution, index|
  puts "#{index + 1}. T: #{solution['T']} P: #{solution['P']} C: #{solution['C']}"
end
