# Python MIMIC Scraper
---


## Run commands

Within a terminal located at the source code directory:
```sh
mpiexec -n <num procs> python -m mpi4py mimic3scraper-mpi.py <downloadFlag> <starIdx> <stopIdx> <onlyDownloadFirstFlag>
```
where:
* num procs is number of processes
* downloadFlag is 1 to download files or 0 to process all files in the directory (if 1 then downloaded files are immediately processed)
* startIdx is first index record download [optional: only if downloadFlag is 1] 
* endIdx is the index of the last record to download [optional: only if downloadFlag is 1]. To download all records (~2 TB) make index -1 
* onlyDownloadFirstFlag indicates whether to only download the first applicable record in each folder (maximises the number of patients in scraped data without the data size exploding)

