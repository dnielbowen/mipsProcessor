import sys
import re

n = 0
for l in sys.stdin.readlines():
    m = re.findall("\s+\w+:\s+((\w\w)(\w\w)(\w\w)(\w\w))\s+(.*)",
        re.sub('\s+', ' ', l));
    print('-- 0x%s %s' % (m[0][0], m[0][5]))
    print('mem(%d)<=x"%s"; mem(%d)<=x"%s"; mem(%d)<=x"%s"; mem(%d)<=x"%s";' %
        (n*4+0, m[0][4], n*4+1, m[0][3], n*4+2, m[0][2], n*4+3, m[0][1]))
    n = n+1
