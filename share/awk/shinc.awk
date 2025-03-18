match($0, /\{\{ *([a-zA-Z0-9_]+) *\}\}/, arr) {
    key = "shinc_args_" arr[1]
    value = ENVIRON[key]
    gsub("\\{\\{ *" arr[1] " *\\}\\}", value)
}
match($0, /^include "(.+)"/, arr) {
    printf "#%s\n", $0
    file = arr[1]
    sub(/~/, ENVIRON["HOME"], file)
    if (system("test -e \"" file "\"") != 0) {
        print "File does not exist: " file >"/dev/stderr"
        exit 1
    }
    while ((getline line < file) > 0)
        print line
    close(file)
    next
}
{ print $0 }
END {
    print "\n# See more details at https://github.com/sigoden/argc"
    print "eval \"$(argc --argc-eval \"$0\" \"$@\")\""
}
