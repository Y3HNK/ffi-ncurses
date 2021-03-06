#!/usr/bin/env ruby -w

# quick and dirty hack to generate function signatures for ruby-ffi
# from ncurses.h

# require 'rubygems'
require 'pp'
# require 'ffi'

signatures = []
base_types = ARGV.delete("--base")
filename = ARGV[0] || '/usr/include/ncurses.h'

# the abstract _p types can be changed to :pointer (= void *)
if base_types
  # ATTR_T          = :uint
  ATTR_T            = :ulong
  ATTR_T_P          = :pointer
  BOOLEAN           = :int
  CCHAR_T_P         = :pointer
  # CCHAR_T         = :cchar_t  # not used in function prototype
  # CHTYPE          = :uint
  CHTYPE            = :ulong
  CHTYPE_P          = :pointer
  FILE_P            = :pointer
  INT_P             = :pointer
  MEVENT_P          = :pointer
#  MMASK_T          = :uint
  MMASK_T           = :ulong
  MMASK_T_P         = :pointer
#  NCURSES_ATTR_T   = :uint
  NCURSES_ATTR_T    = :ulong
  NCURSES_OUTC      = :pointer
  NCURSES_SCREEN_CB = :pointer
  NCURSES_WINDOW_CB = :pointer
  PANEL_P           = :pointer
  SCREEN_P          = :pointer
  SHORT_P           = :pointer
  WINDOW_P          = :pointer
  WCHAR_T           = :ushort             # analogous to the `char` type (but wider)
  WCHAR_T_P         = :pointer
  WINT_T            = :uint               # wider than wchar_t (so can hold WEOF)
  WINT_T_P          = :pointer
else
  ATTR_T            = :attr_t
  ATTR_T_P          = :attr_t_p
  BOOLEAN           = :bool
  CCHAR_T_P         = :cchar_t_p
  # CCHAR_T         = :cchar_t  # not used in function prototype
  CHTYPE            = :chtype
  CHTYPE_P          = :chtype_p
  FILE_P            = :file_p
  INT_P             = :int_p
  MEVENT_P          = :mevent_p
  MMASK_T           = :mmask_t
  MMASK_T_P         = :mmask_t_p
  NCURSES_ATTR_T    = :attr_t
  NCURSES_OUTC      = :pointer # :putc_callback     # typedef int (*NCURSES_OUTC)(int);
  NCURSES_SCREEN_CB = :pointer # :screen_callback   # typedef int (*NCURSES_SCREEN_CB)(SCREEN *, void *);
  NCURSES_WINDOW_CB = :pointer # :window_callback   # typedef int (*NCURSES_WINDOW_CB)(WINDOW *, void *);
  PANEL_P           = :panel_p
  SCREEN_P          = :screen_p
  SHORT_P           = :short_p
  WINDOW_P          = :window_p
  WCHAR_T           = :wchar_t           # analogous to the `char` type (but wider)
  WCHAR_T_P         = :wchar_t_p
  WINT_T            = :wint_t            # wider than wchar_t (so can hold WEOF)
  WINT_T_P          = :wint_t_p
end

@typemap = {
  "..."               => :varargs,
  "FILE*"             => FILE_P,
  "MEVENT*"           => MEVENT_P,
  "NCURSES_ATTR_T"    => NCURSES_ATTR_T,
  "NCURSES_OUTC"      => NCURSES_OUTC,      # function pointer to putc type function - see vidputs
  "NCURSES_SCREEN_CB" => NCURSES_SCREEN_CB,
  "NCURSES_WINDOW_CB" => NCURSES_WINDOW_CB,
  "PANEL*"            => PANEL_P,
  "SCREEN*"           => SCREEN_P,
  "WINDOW*"           => WINDOW_P,
  "_Bool"             => BOOLEAN,
  "attr_t"            => ATTR_T,
  "attr_t*"           => ATTR_T_P,
  "bool"              => BOOLEAN,
  # "cchar_t"         => CCHAR_T,        # wide character support - cchar_t is a struct
  "cchar_t*"          => CCHAR_T_P,      # wide character support - cchar_t is a struct
  "char"              => :char,
  "char*"             => :string,
  "chtype"            => CHTYPE,
  "chtype*"           => CHTYPE_P,
  "int"               => :int,
  "int*"              => INT_P,
  "long"              => :long,
  "mmask_t"           => MMASK_T,
  "mmask_t*"          => MMASK_T_P,
  "short"             => :short,
  "short*"            => SHORT_P,
  "unsigned int"      => :uint,
  "va_list"           => [:unmapped, :va_list],
  "void"              => :void,
  "void*"             => :pointer,
  "wchar_t"           => WCHAR_T,         # analogous to the `char` type (but wider)
  "wchar_t*"          => WCHAR_T_P,
  "wint_t"            => WINT_T,           # wider than wchar_t (so can hold WEOF)
  "wint_t*"           => WINT_T_P,
}

def map_type(t)
  t = t.gsub(/(NCURSES_)?CONST/i,'').strip.gsub(/\s+\*/, '*')
  @typemap.key?(t) ? @typemap[t] : [:unmapped, t]
end

# these patterns are specific to the ncurses.h include file
RX_RETURN_TYPE = '\\(.*?\\)'
RX_IDENTIFIER = '[A-Za-z_][A-Za-z_0-9]*'
RX_ARGS = "\\((.*?)\\)"
RX_BRACKETS = '[()]'
# RX_EXPORT = 'extern\\s+((NCURSES_)?EXPORT)?'
RX_EXPORT = 'extern|const'

line_counter = 0
IO.readlines(filename).each do |line|
  begin
    line_counter += 1
    if line =~ /#{RX_EXPORT}.*\(/i
      txt = line.gsub(/#{RX_EXPORT}/i, '').strip
      #p [:txt, txt]
      # return_type = txt.match(/(#{RX_RETURN_TYPE})/).captures[0]

      args = txt.match(RX_ARGS)
      if args
        args = args.captures[0]
        args = args.gsub(/#{RX_BRACKETS}/, '').split(/\s*,\s*/).map{|x| map_type(x)}
      else
        STDERR.puts "skipping line: #{line}"
        next
      end
      #p [:args, args]
      txt = txt.gsub(/\s*#{RX_ARGS}\s*;?\s*$/, '')
      #p [:txt, txt]

      tokens = txt.split
      method_name = tokens[-1]
      return_type = tokens[0..-2].join(" ")
      #p [:return_type, return_type]
      return_type = return_type.gsub(/#{RX_BRACKETS}/, '')
      return_type = return_type.gsub(/\s+\*/, '*')
      return_type = map_type(return_type)
      #p [:return_type_mapped, return_type]

      signatures << [method_name.to_sym, args == [:void] ? [] : args, return_type]
    else
      STDERR.puts "skipping line: #{line}"
    end
  rescue => e
    #p [:exception, e, :line, line_counter, line]
  end
end

# discard sigs of functions we can't handle
unmapped, sigs = signatures.partition{ |s| s.flatten.include?(:unmapped)}

# handle wrapped functions
# e.g.
#   [:initscr, [], :window_p],
# becomes
#   [:_wrapped_initscr, :initscr, [], :window_p],
# i.e. insert _wrapped_#{sig[0]} name in front
#
wrapped = [
           :clearok,            # bool arg
           :idcok,              # bool arg
           :idlok,              # bool arg
           :immedok,            # bool arg
           :initscr,            # to define ACS constants after call
           :intrflush,          # bool arg
           :keyok,              # bool arg
           :keypad,             # bool arg
           :leaveok,            # bool arg
           :meta,               # bool arg
           :mouse_trafo,        # bool arg
           :nodelay,            # bool arg
           :notimeout,          # bool arg
           :scrollok,           # bool arg
           :newterm,            # to define ACS constants after call
           :syncok,             # bool arg
           :use_env,            # bool arg
           :use_extended_names, # bool arg
           :wmouse_trafo,       # bool arg
          ]

sigs = sigs.map{ |sig|
  m = sig[0]
  if wrapped.include?(m)
    ["_wrapped_#{m}".to_sym] + sig
  else
    sig
  end
}

puts "module FFI
  module NCurses
    # this list of function signatures was generated by the file #{__FILE__}
    FUNCTIONS =
      [
       #{ sigs.sort_by { |x| x[0].to_s }.map{ |sig| sig.inspect }.join(",\n       ") },
      ]
    # end of autogenerated function list
  end
end
"

STDERR.puts "# unmapped functions"
STDERR.puts unmapped.sort_by{ |x| x.to_s }.pretty_inspect

#puts "# #{sigs.size}"
#puts "# #{unmapped.size}"
