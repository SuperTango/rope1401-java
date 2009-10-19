PROG=i1401r
SRCS := $(wildcard *.c)
OBJS := $(patsubst %.c,%.o,$(wildcard *.c))
HDRS=*.h
builddir=build
srcdir=.

CC=gcc
CFLAGS=

ODIR=obj

_OBJ = $(OBJS)
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))


$(ODIR)/%.o: %.c $(ODIR)
	$(CC) -c -o $@ $< $(CFLAGS)

$(PROG): $(OBJ)
	gcc -o $@ $^ $(CFLAGS) $(LIBS)

$(ODIR):
	mkdir -p $(ODIR)

clean:
	rm -f $(ODIR)/*.o  $(PROG)
	rmdir $(ODIR)
