package utils

import "time"

// UTCNow ...
func UTCNow() time.Time {
	return time.Now().UTC()
}
