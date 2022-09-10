BEGIN { ops = 0
	time = 0
       	}
/^...r/ { print $2, $3 }
/^...[0-9A-F] / { ops = ops + $2
	time = time + $3
	}
END { print ops, time }

