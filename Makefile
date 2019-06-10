all: tappity

tappity: tappity.m
	clang -framework AppKit -g -o tappity tappity.m
