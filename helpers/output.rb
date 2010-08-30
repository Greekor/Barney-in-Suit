# prints block to filename
# XXX: used?
def out(filename)
  File.open(filename, "w") { |file|
    $ident = 0
    file.write yield if block_given?
  }
end

# some kind of XML output
# XXX: used?
def tag(name, *args)
  items = args[0] || {}
  if block_given?
    $ident += 1
    content = yield.to_s || ""
    $ident -= 1
  else
    #content = (items.has_key?(:text) ? items[:text] : "")
    content = ""
  end

  "  "*$ident + "<#{name}" + (items.empty? ? "" : ' '+items.map { |key,val| "#{key}=\"#{val.to_s}\"" }.join(" ")) + ">" + (content.include?("\n") ? "\n"+content+ "  "*$ident : content) + "</#{name}>\n"
#  $fh.puts("<#{tag]>
end