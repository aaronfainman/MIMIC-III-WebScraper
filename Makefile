# Compiler settings

CC = g++
CFLAGS = -fopenmp -lgomp -lpthread

# Compilation dependencies

DATAMINER: main.o
	$(CC) $(CFLAGS) main.o -o DATAMINER

main.o: main.cpp
	$(CC) $(CFLAGS) -c main.cpp

# OMP_Functions.o: OMP_Functions.cpp OMP_Functions.h
# 	$(CC) $(CFLAGS) -c OMP_Functions.cpp

# Array2D.o: Array2D.cpp Array2D.h
# 	$(CC) $(CFLAGS) -c Array2D.cpp

# Array3D.o: Array3D.cpp Array3D.h
# 	$(CC) $(CFLAGS) -c Array3D.cpp

# MultiplicationStructures.o: MultiplicationStructures.cpp MultiplicationStructures.h
# 	$(CC) $(CFLAGS) -c MultiplicationStructures.cpp

# PThread_Functions.o: PThread_Functions.cpp PThread_Functions.h
# 	$(CC) $(CFLAGS) -c PThread_Functions.cpp

# Clean build
 
clean:
	rm -rf output
	rm *.o DATAMINER