# Process the data recived from the student transcript by the SigaaParser
module TranscriptDataProcessor
  # Return an array without headers
  # Semester formatted for chart, real average, only approved courses average
  # [ [ { v: 0, f: '2015.1' }, 6.7, 8.5 ], ...  ]
  def self.semesters_average(course_results)
    output = []

    # Do not iterate over last (current?) semester
    course_results.semesters[0..-2].each_with_index do |semester, index|
      output << [{ v: index, f: semester },
                 course_results.average_up_to(semester),
                 course_results.average_up_to(semester, approved_only: true)]
    end

    output
  end

  # Return an array without headers
  # Semester formatted for chart and yours semesters workload by situation
  # (Sum of each course credits)
  # [ [ { v: 1, f: '2011.1' }, 28, 4, 0 ], ... ]
  def self.semesters_workload(course_results)
    output = []

    # Gets the courses situations for that student
    courses_situations = course_results.results.group_by(&:situation).keys
    output << (['Semestre'] + courses_situations)

    # Calculate the sum of credits by each semester grouped by course situation
    course_results.semesters.each_with_index do |semester, index|
      # Get the current semester courses
      semester_courses = course_results.results.select { |result| result.semester == semester }
      local_array = [{ v: (index + 1), f: semester }]

      # On current semester courses, iterate over each situation adding the courses credits
      courses_situations.each do |situation|
        courses_by_situation = semester_courses.select { |result| result.situation == situation }
        local_array.push(courses_by_situation.blank? ? nil : courses_by_situation.sum(&:credits))
      end

      output << local_array
    end

    output
  end

  # Return an hash { APROVADO: 20, REPROVADO: 30, ... }
  def self.courses_grouped_by_situation(course_results)
    # Group courses by situation
    output = course_results.results.group_by(&:situation)

    # Replace courses with count
    output.each do |situation, courses|
      output[situation] = courses.count
    end

    # Sort by count
    output.sort_by { |_, count| count }.reverse
  end

  # Return array with headers and
  #    { max_grade: <max_grade>, min_grade: <min_grade>,
  #      max_semester: <max_semester> }
  # Check: https://developers.google.com/chart/interactive/docs/gallery/bubblechart#data-format
  # [ ID, X, Y, Color, Size]
  # [ Course name, Semester formatted for chart, Grande, Grade, Credits ]
  def self.courses_for_bubble(course_results)
    # Filter courses (remove REP. FALTA and MATRICULADO)
    situations = %w(APROVADO REPROVADO DISPENSADO)
    courses = course_results.results.select { |course| situations.include?(course.situation) }

    # Make semesters map for bubble chart
    # { 2015.1: 0, 2015.2: 1, 2016.1: 2, ...}
    semesters_map = {}

    courses.map(&:semester).uniq.sort.each_with_index do |semester, index|
      semesters_map[semester] = index
    end

    # Header
    output = []

    courses.each do |result|
      output << [result.name,
                 { v: semesters_map[result.semester],
                   f: result.semester },
                 result.grade.to_f,
                 result.grade.to_f,
                 result.credits.to_i]
    end

    # Calculate statistics
    stats = {}
    stats[:max_grade] = output.map { |row| row[2] }.max
    stats[:min_grade] = output.map { |row| row[2] }.min
    stats[:max_semester] = semesters_map.values.max

    # Add header to beginning of array
    output.unshift(%w(ID Semestre Nota Nota Créditos))

    return output, stats
  end
end
