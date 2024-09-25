
require 'nokogiri'

# Load our custom BJC tools
require_relative '../build-tools/bjc_helpers'
require_relative '../build-tools/course'
require_relative '../build-tools/topic'

module BJCSpecs
  # The list of all courses in BJC
  COURSES = %w[
    bjc4nyc
    bjc4nyc.es
    sparks
    bjc4nyc_teacher
    sparks-teacher
  ]

  # This is a map of all courses/groups
  ALL_PAGES = {}
  ALL_PAGES['general'] = [
    '/bjc-r/',
    '/bjc-r/docs/style_guide.html',
    '/bjc-r/docs/best_practices.html',
    '/bjc-r/docs/translations.html',
    '/bjc-r/topic/topic.html',
    '/bjc-r/topic/topic.es.html',
    '/bjc-r/sparks/design-principles.html',
    '/bjc-r/mini/index.html'
  ]

  def load_site_urls(courses)
    # Map is a course_name => [url1, url2, ...]
    courses.map do |course|
      puts "Building URLs for #{course}..."
      [course, load_all_urls_in_course("#{course}.html")]
    end.to_h
  end

  def extract_urls_from_page(topic_file, course)
    topic_file = File.join(File.dirname(__FILE__), '..', '..', 'topic', topic_file)
    lang = topic_file.match(/\.(\w\w)\.topic/) ? Regexp.last_match(1) : 'en'
    topic_parser = BJCTopic.new(topic_file, course: course, language: lang)
    topic_parser.augmented_page_paths_in_topic
  end

  def load_all_urls_in_course(course)
    # Read the course page, then add all "Unit" URLs to the list
    # TODO: Use the BJCCourse class to extract the URLs
    results = [ "/bjc-r/course/#{course}" ]
    course_file = File.join(File.dirname(__FILE__), '..', '..', 'course', course)
    doc = Nokogiri::HTML(File.read(course_file))
    urls = doc.css('.topic_container .topic_link a').map { |url| url['href'] }

    topic_pages = urls.filter_map do |url|
      next unless url.match?(/\.topic/)

      query_separator = url.match?(/\?/) ? '&' : '?'
      results << "#{url}#{query_separator}course=#{course}"
      topic_file = url.match(/topic=(.*\.topic)/)[1]
      extract_urls_from_page(topic_file, course)
    end.flatten

    results << topic_pages
    results << urls.filter_map { |url| "#{url}#{url.match?(/\?/) ? '&' : '?'}course=#{course}" if !url.match?(/\.topic/) }
    results.flatten.reject { |u| !u.start_with?('/bjc-r') }.uniq
  end

  def complete_bjc_grouped_file_list(courses)
    ALL_PAGES.merge(load_site_urls(courses))
  end
end
