BEGIN { split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month)
        print "From its-bugs@mit"
	header=1 }
/^$/ { print "From its-bugs@mit"; header=1; next }
header && /^From / { print ">" $0; next }
header && /^Date: / {
    if (match($0, /^(.* 1?9?[7-9][0-9]),? [0-9][0-9]:?[0-9][0-9](:[0-9][0-9])?-...$/, x))
	print x[1] ", 00:00"
    else if (match($0, /^(Date: )([0-9]+) ([A-Za-z]+)( [0-9].*)$/, x))
	print x[1] x[3] " " x[2] x[4]
    else if (match($0, /^(Date: )([A-Za-z]+, )([0-9]+) ([A-Za-z]+)( [0-9].*)$/, x))
	print x[1] x[4] " " x[3] x[5]
    else
	print $0
    next
}
header && /^[A-Z, ]+@[A-Z-]+ / {
    if (match($0, /^([A-Z]+@[A-Z-]+) (..)\/(..)\/(..)/, x)) {
	print "Date: " x[3] " " month[x[2]+0] " 19" x[4] " 00:00"
	print "From: " x[1]
    } else if (match($0, /\(Sent by (.*)\) (..)\/(..)\/(..)/, x)) {
	print "Date: " x[3] " " month[x[2]+0] " 19" x[4] " 00:00"
	print "From: " x[1]
    } else
	print $0
    if (match($0, / Re: (.*)$/, x))
	print "Subject: " x[1]
    next
}
heder && /^$/ { header=0 }
{ print $0 }
