package utils

import (
	uuid "github.com/satori/go.uuid"
)

// UUID new a uuid
func UUID() string {
	return uuid.Must(uuid.NewV4()).String()
}
