rm -f its-bugs.mbox
for i in its.obugs0 its.obugs1 its.obugs2 its.bugs; do
    cat $i | gawk -f its-bugs.awk >> its-bugs.mbox
done
