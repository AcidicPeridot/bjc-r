require 'fileutils'
require 'rio'
require_relative 'selfcheck'

class Vocab
	
	def initialize(path)
		@parentDir = path
		@currFile = nil
		@currIndex = 0
		@currPath = path
		@currUnit = nil
		@currFile = nil
		@currLine = ''
		@listLines = []
		@isNewUnit = true
		@currUnitNum = 0
		@currLab = ''
		@vocabFileName = ''
		@pastFileUnit = nil
		#@selfcheck = SelfCheck.new(path)
		@currUnitName = nil
	end

	def currUnitName(name)
		@currUnitName = name
	end

	def selfcheck()
		#@selfcheck
	end

	def currUnit(str)
		@currUnit = str
	end

	def currFile(file)
		@currFile = file
	end

	def currIndex(i)
		@currIndex = i
	end

	def currFile(file)
		@currFile = file
	end

	def currLine(line)
		@currline = line
	end

	def listLines(file)
		@listLines = File.readlines(file)
	end

	def currPath(path)
		@currPath = path
	end

	def isNewUnit(boolean)
		@isNewUnit = boolean
	end

	def currUnitNum(num)
		@currUnitNum = num
	end

	def vocabFileName(name)
		@vocabFileName = name
	end

	def currLab()
		if @currUnit != nil
			labMatch = @currUnit.match(/Lab.+,/)
			labList =  labMatch.to_s.split(/,/)
			@currLab = labList.join
		end
	end

	def pastFileUnit(unit)
		@pastFileUnit = unit
	end

	def read_file(file)
		listLines(file)
		currIndex(0)
		currFile(file)
		#@selfcheck.currFile(file)
		#@selfcheck.currIndex(0)
		#@selfcheck.listLines(file)
		isNewUnit(true)
		parse_unit(file)
		parse_vocab(file)
		#@selfcheck.parse_assessmentData(line, @currIndex)
		puts "Completed:  #{@currUnit}"
	end


	def parse_unit(file)
		doc = File.open(file) { |f| Nokogiri::HTML(f) }
		title = doc.xpath("//title")
		str = title.to_s
		pattern = /<\/?\w+>/
		if (str == nil or not(@isNewUnit))
			nil
		else
			#add_to_file("Units.txt", str.match(pattern).to_s)
			newStr = str.split(pattern)
			currUnit(newStr.join)
			currUnitNum(@currUnit.match(/\d+/).to_s)
			vocabFileName("vocab#{@currUnitNum}.html")
			#@selfcheck.currUnit(@currUnit)
			#@selfcheck.currUnitNum(@currUnitNum)
			#@selfcheck.assessmentFileName("assess-data#{@currUnitNum}.html")
			isNewUnit(false)
		end
	end

	def createNewVocabFile(fileName)
		i = 0
		if not(File.exist?(fileName))
			File.new(@vocabFileName, "w")
		end
		linesList =  rio(@currFile).lines[0..15] 
		while (linesList[i].match(/<body>/) == nil)
			if linesList[i].match(/<title>/)
				File.write(fileName, "<title>Unit #{@currUnitNum} Vocabulary</title>\n", mode: "a")
			else
				File.write(fileName, "#{linesList[i]}\n", mode: "a")
			end
			i += 1
		end
		File.write(fileName, "<h2>#{@currUnit}</h2>\n", mode: "a")
		File.write(fileName, "<h3>#{currLab()}</h3>\n", mode: "a")
	end

	def add_HTML_end()
		Dir.chdir("#{@parentDir}/summaries")
		ending = "</body>\n</html>"
		File.write(@vocabFileName, ending, mode: "a")
	end



	def add_content_to_file(filename, data)
		lab = @currLab
		if File.exist?(filename)
			if lab != currLab()
				File.write(filename, "<h3>#{currLab()}</h3>\n", mode: "a")
			end
			File.write(filename, data, mode: "a")
		else
			createNewVocabFile(filename)
			File.write(filename, data, mode: "a")
		end	
	end	



	#might need to save index of line when i find the /div/ attribute
	#might be better to have other function to handle that bigger parsing of the whole file #with io.foreach
	def parse_vocab(file)
		doc = File.open(file) { |f| Nokogiri::HTML(f) }
		vocabSet = doc.xpath("//div[@class = 'vocabFullWidth']")
		#header = parse_vocab_header(doc.xpath(""))
		vocabSet.each do |node|
			child = node.children()
			child.before(add_vocab_unit_to_header())
		end
		if not(vocabSet.empty?())
			add_vocab_to_file(vocabSet.to_s)
		end
	end

	def parse_vocab_header(str)
		newStr1 = str
		if str.match(/vocabFullWidth/)
			if str.match(/<!--.+-->/)
				newStr1 = str.gsub(/<!--.+-->/, "")
			end
			newStr2 = newStr1.to_s
			if (newStr2.match(/<div class="vocabFullWidth">.+/))
				headerList = newStr2.split(/:/)
			else
				headerList = []
				headerList.push(str)
			end
			headerList
		else
			[]
		end

	end

	def add_vocab_unit_to_header()
		unitNum = return_vocab_unit(@currUnit)
		link = " <a href=\"#{get_url(@currFile)}\">#{unitNum}</a>"
		return link
		#if lst.size > 1
		#	unitSeriesNum = lst.join(" #{withlink}:")
		#else
		#	unitSeriesNum = lst
		#	unitSeriesNum.push(" #{withlink}:")
		#	unitSeriesNum.join
		#end
	end

	#need something to call this function and parse_unit
	def return_vocab_unit(str)
		list = str.scan(/(\d+)/)
		list.join('.')
	end

	def add_vocab_to_file(vocab)
		result = "#{vocab} \n\n"
		add_content_to_file("#{@parentDir}/summaries/#{@vocabFileName}", result)
	end

	def get_url(file)
		localPath = Dir.getwd()
		linkPath = localPath.match(/bjc-r.+/).to_s
		result = "https://bjc.berkeley.edu/#{linkPath}/#{file}"
		result = "#{result}"
		#add_content_to_file('urlLinks.txt', result)
	end

end