callable() {
	[ -n "$(type $1 2> /dev/null)" ]
}

# vim: set tabstop=4 shiftwidth=4 noexpandtab:
