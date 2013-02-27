DC=dmd
D_FLAGS=-O -w -wi

all: ./bin/simplefat ./bin/ddemangle
	/bin/rm -f ./bin/*.o

./bin/simplefat:
	$(DC) $(D_FLAGS) -of./bin/simplefat -I./simpleFATEditor/ ./simpleFATEditor/repl.d ./simpleFATEditor/editor.d

./bin/ddemangle: 
	$(DC) $(D_FLAGS) -of./bin/ddemangle ./demangler/ddmangle.d


clean:
	/bin/rm -f ./bin/ddemangle
	/bin/rm -f ./bin/simplefat
