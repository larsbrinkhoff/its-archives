rm -f its-hackers.mbox
find its-hackers -type f | while read i; do
    if head -1 $i | grep "^From its-hackers" >/dev/null; then
	echo -n .
	head -1 $i >> its-hackers.mbox
	tail -n +2 $i | sed -e 's/^From />From /' >> its-hackers.mbox
    else
	echo -n '!'
	echo "From its-hackers@cosmic.com" >> its-hackers.mbox
	cat $i | sed -e 's/^From />From /' >> its-hackers.mbox
    fi
done
echo
