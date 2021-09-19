from bs4 import BeautifulSoup
import requests
import os
from mpi4py import MPI
import numpy as np
import math

ROOTURL = "https://physionet.org/files/mimic3wdb/1.0"
ROOTFOLDER = "./physionet.org/files/mimic3wdb/1.0/"
NUMTHREADS = 8
TEXTDATAFOLDER = './physionet.org/textdata/'
ABPANNFOLDER = "./physionet.org/abp_ann/"

comm = MPI.COMM_WORLD

IS_POSIX = os.name=='posix'

def getRecordList(url):
    #scrape root directory from physionet MIMICIII waveform (only)
    
    recordsRequest = requests.get(url + "/RECORDS-waveforms")

    #convert request item in Soup obj and into vector of string names
    soup = BeautifulSoup(recordsRequest.text, 'html.parser')

    #choose random selection of 100 records
    #all_record_paths = random.sample(str(soup).splitlines(),100)
    all_record_paths = str(soup).splitlines()
    return all_record_paths


def scrape_mimic_list(record_paths,numprocs):
    filesDownloaded = []
    progress = 0
    for record_path in record_paths:
        progress +=1
        printCollectiveProgress(progress/len(record_paths), "Download Progress", numprocs)
        filesDownloaded.extend(scrape_mimic(record_path=record_path))
    printCollectiveProgress(1, "Download Progress", numprocs)
    return filesDownloaded

def scrape_mimic(record_path):

    filesDownloaded = []
    #Will look in each record's general layout file for presence of an ABP and PLETH waveform
    #    if it exists then will download file
    RecordsInFolderRequest = requests.get(ROOTURL + "/" + record_path + "/RECORDS")
    all_records_in_folder = str(BeautifulSoup(RecordsInFolderRequest.text, 'html.parser')).splitlines()

    for record in all_records_in_folder:
        HeaderRequest = requests.get(ROOTURL + "/" + record_path + record + ".hea")
        soup_layout = BeautifulSoup(HeaderRequest.text, 'html.parser')
        signalData = str(soup_layout).splitlines()[1:]
        signalList = []
        for line in signalData:
            signalList.append(line.split()[-1])
        signal_matches = ["ABP", "PLETH"] 
        
        if not all(a in signalList for a in signal_matches):
            continue
        #use --no-parent otherwise you will download all directory files
        # -q suppresses command line output of download
        filePath = record_path + record
        download_cmd = "wget -r -q --no-parent " + ROOTURL + "/" + filePath;
        
        # For use with Windows (with WSL) add wsl add beginning of system command
        if not IS_POSIX: 
            download_cmd = "wsl "+ download_cmd

        #check if files have already been downloaded otherwise download them
        if not os.path.isfile(ROOTFOLDER+filePath+".dat"):
            # print("DOWNLOADING -- " + filePath )
            os.system(download_cmd +".dat") #fg; echo DOWNLOADED
        if not os.path.isfile(ROOTFOLDER+filePath+".hea"):
            # print("DOWNLOADING -- " + filePath )
            os.system(download_cmd +".hea") #fg; echo DOWNLOADED
        # print("DOWNLOAD COMPLETE -- " + filePath)
        filesDownloaded.append(record)

    return filesDownloaded

def getListOfFiles(inFolder, ext):
    fileList = []
    for rootfolder, folder, filenames in os.walk(inFolder):
        for filename in [file for file in filenames if file.endswith(ext)]:
            fileList.append(os.path.join(filename[0:2],filename[0:7], filename[0:12]))
    return fileList

def convertToText(dataFileList, numprocs):
    fileThreshold = 17*1024

    if not os.path.isdir(TEXTDATAFOLDER):
        os.mkdir(TEXTDATAFOLDER)
    
    progress = 0;
    for record in dataFileList:
        filePath = ROOTFOLDER+record
        fileSize =  os.path.getsize(filePath+'.dat')
        progress += 1;
        printCollectiveProgress(progress/len(datfileList), "Conversion Progress", numprocs)
        if fileSize > fileThreshold:
            # Convert to TXT
            #rdsamp: to text is -p > newName.txt
            # -s : signal list is ABP, PLETH in that order => output cols will be TIME-ABP-PLETH
            # -S : search for first valid time for ABP
            rdsamp_cmd = "taskkill /im rdsamp -r " + filePath +" -p > " + filePath + ".txt -s ABP PLETH -S ABP /f >/dev/null 2>&1"
            if not IS_POSIX: 
                rdsamp_cmd = "wsl " + rdsamp_cmd

            # print('CONVERTING TO TXT -- ' + filePath)
            # print(rdsamp_cmd)
            os.system(rdsamp_cmd)
            # print('CONVERTING TO TXT COMPLETE -- ' + filePath)
            # move converted files to new folder
        
            move_cmd = "taskkill /im mv " + filePath +".txt " + TEXTDATAFOLDER + "/f >/dev/null 2>&1"
            if not IS_POSIX:
                move_cmd = "wsl "+ move_cmd
            # print(move_cmd)
            os.system( move_cmd )
    printCollectiveProgress(1, "Conversion Progress", numprocs)
        

def extractAbpBeats(fileList):
    # Generate wabp files and extract to text:
  
    if not os.path.isdir(ABPANNFOLDER):
        os.mkdir(ABPANNFOLDER)

    progress = 0;
    for f in fileList:
        # print('EXTRACTING ABP -- ' + f)
        wabp_cmd = "taskkill /im  wabp -r " + ROOTFOLDER + f + " /f >null 2>&1"
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd)
        #output from command suppressed using: taskkill /im <rdann command> /f >null 2>&1
        wabp_cmd = "taskkill /im rdann -r " + ROOTFOLDER + f + " -a wabp >" + ABPANNFOLDER + f[11:]+"_abp.txt /f >null 2>&1"
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd) 
        
        progress += 1
        printCollectiveProgress(progress/len(fileList), "ABP Extraction Progress", numprocs)
    printCollectiveProgress(1, "ABP Extraction Progress", numprocs)
        # print('ABP EXTRACTION COMPLETE -- ' + f)

import time
def printCollectiveProgress(progress, message, numprocs):
    global comm
    coll_progress = comm.gather(progress, root=0);
    if comm.Get_rank()!=0:
        return 0;
    
    perc_progress = int(sum(coll_progress)*100//numprocs);

    progress_text = "|"
    for i in range(perc_progress//5):
        progress_text += '\u2590'
    for i in range(perc_progress//5,20):
        progress_text += "-"
    progress_text += "|"
    print(" ",message,":", progress_text, perc_progress, "%",end='\r')



if __name__ == '__main__':


    rank = comm.Get_rank()
    numprocs = comm.Get_size()

    print("Rank " + str(rank) + " starting...")



    if rank == 0:
        allRecordPaths = getRecordList(ROOTURL)
        allRecordPaths = allRecordPaths[10:14]
        amountToProc = len(allRecordPaths)//numprocs
        sendRecs = []
        #MPI scatter requires scattering a list with num elements equal to num proceses
        # reshape the list of records into a list of lists where number of lists equals num processes
        # and within each list the number of elements varies
        for idx in range(numprocs-1):
            sendRecs.extend( [allRecordPaths[idx*amountToProc:idx*amountToProc+amountToProc]] )
        sendRecs.extend( [allRecordPaths[(numprocs-1)*amountToProc:len(allRecordPaths)]] )
    else:
        sendRecs = None
    
    myRecords = []
    myRecords = comm.scatter(sendRecs, root=0)
    
    # print(rank, " - ", myRecords)
    print("\nBeginning downloads.") if rank==0 else 0
    myFilesDownloaded = scrape_mimic_list(myRecords, numprocs)
    print("\nDownloads complete.") if rank==0 else 0

    comm.Barrier()
    
    datfileList = getListOfFiles(ROOTFOLDER, '.dat')
    numRecords = len(datfileList)//numprocs
    if rank == numprocs:
        datfileList = datfileList[rank*numRecords:]
    else:
        datfileList = datfileList[rank*numRecords:(rank+1)*numRecords]


    print("Converting to text") if rank==0 else 0;
    convertToText(datfileList,numprocs)

    print("\nExtracting ABP") if rank==0 else 0;
    extractAbpBeats(datfileList)
    print("\nABP extraction complete") if rank==0 else 0;
    print("Completed successfully") if rank ==0 else 0;

