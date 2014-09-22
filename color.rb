module Color
  
  Table = {
    "@D" => "\e[0m",
    "@d" => "\e[0m",
    "@m" => "\e[0;35m",
    "@b" => "\e[0;34m",
    "@c" => "\e[0;36m",
    "@g" => "\e[0;32m",
    "@y" => "\e[0;33m",
    "@r" => "\e[0;31m",
    "@w" => "\e[1;30m",
    "@M" => "\e[1;35m",
    "@B" => "\e[1;34m",
    "@C" => "\e[1;36m",
    "@G" => "\e[1;32m",
    "@Y" => "\e[1;33m",
    "@R" => "\e[1;31m",
    "@W" => "\e[0;37m",
    "@@" => "@"
  }
  
  def self.cformat(str, defcolor = 'd')
    ctable = Table.merge({"@D" => defcolor})
    str.gsub(/@[brmcygwdBRMCYGWD@]/, ctable)
  end
  
end