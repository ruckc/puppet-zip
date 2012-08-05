module Puppet
	newtype(:zipfile) do
		@doc = "Ensure contents of file within a zip file"

		require 'zip/zip'

		newparam(:zip) do
			desc "The path to the zip file which contains the file"
			isnamevar
		end
		newparam(:file) do
			desc "The file path within the zip file"
			isnamevar
		end
		newparam(:content) do
			desc "The contents of the file within the zip file"
		end

		newproperty(:ensure) do
			desc "Ensures the content of the file inside the zip file is in sync"

			defaultto :present
			newvalue :present do
				Zip::ZipFile.open(@resource[:zip]) do |z|
					z.get_output_stream(@resource[:file]) { |f| f.puts @resource[:content] }
				end
			end

			newvalue :absent do
				Zip::ZipFile.open(@resource[:zip]) do |z|
					z.remove(@resource[:file])
				end
			end

			def retrieve
				if not File.exists?(@resource[:zip])
					raise Puppet::Error, "Zip file does not exist #{@resource[:zip]}"
				end
				content = nil
				begin
					Zip::ZipFile.open(@resource[:zip]) do |z|
						content=z.read(z.get_entry(@resource[:file]))
					end
				rescue
					nil
				end
				ret = nil
				if not content
					debug("File does not exist in zipfile (#{@resource[:file]})")
					ret = :absent
				elsif @resource[:content]
					require 'digest/md5'
					a = Digest::MD5.hexdigest(content)
					b = Digest::MD5.hexdigest(@resource[:content])
					debug("Comparing content of #{a} with #{b}")
					return a == b ? :present : :absent
				else
					debug("No provided content, but its ok, because its not supposed to be there")
					return content ? :present : :absent
				end
			end
		end

  	# Where we setup autorequires.
	  autorequire(:zip) do
		  auto_requires = []
			[:zip].each do |param|
				if @parameters.include?(param)
					auto_requires << @parameters[param].value
				end
			end
			auto_requires
		end

		# Our title_patterns method for mapping titles to namevars for supporting
		# composite namevars.
		def self.title_patterns
			identity = lambda {|x| x}
			[[
				/^(.*):(.*)$/,
				[
					[ :zip, identity ],
					[ :file, identity ]
				]
			]]
		end
	end
end
