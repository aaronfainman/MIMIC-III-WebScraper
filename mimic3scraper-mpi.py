from bs4 import BeautifulSoup
import requests
import os
from mpi4py import MPI
import numpy as np
# import math
import sys
import datetime

ROOT = "./"

ROOTURL = "https://physionet.org/files/mimic3wdb/1.0"
ROOTFOLDER = ROOT + "physionet.org/files/mimic3wdb/1.0/"
NUMTHREADS = 8
TEXTDATAFOLDER = ROOT + "physionet.org/textdata/"
ABPANNFOLDER = ROOT + "physionet.org/abp_ann/"
FILESDOWNLOADEDRECORD = ROOT+"physionet.org/files_downloaded.txt"

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
    global comm
    filesDownloaded = []
    progress = 0
    # printDownloadProgress(0,len(record_paths), len(filesDownloaded) )
    if(comm.Get_rank()==0):
        print("  downloading record: ")
    for record_path in record_paths:
        print(record_path)
        filesDownloaded.extend(scrape_mimic(record_path=record_path))
        progress +=1
        # printDownloadProgress(progress, len(record_paths), len(filesDownloaded) )
    # printDownloadProgress(len(record_paths),len(record_paths), len(filesDownloaded) )
    return filesDownloaded

def scrape_mimic(record_path):

    filesDownloaded = []
    #Will look in each record's general layout file for presence of an ABP and PLETH waveform
    #    if it exists then will download file
    try:
        RecordsInFolderRequest = requests.get(ROOTURL + "/" + record_path + "RECORDS")
    except:
        return []

    all_records_in_folder = str(BeautifulSoup(RecordsInFolderRequest.text, 'html.parser')).splitlines()

    for record in all_records_in_folder:
        try:
            HeaderRequest = requests.get(ROOTURL + "/" + record_path + record + ".hea")
        except:
            continue
            
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
        print("\t "+ record, end="\r")
        download_cmd = "wget -r -q --no-parent " + ROOTURL + "/" + filePath
        
        # For use with Windows (with WSL) add wsl add beginning of system command
        if not IS_POSIX: 
            download_cmd = "wsl "+ download_cmd

        #check if files have already been downloaded otherwise download them
        try:
            if not os.path.isfile(ROOTFOLDER+filePath+".dat"):
                # print("DOWNLOADING -- " + filePath )
                os.system(download_cmd +".dat") #fg; echo DOWNLOADED
            if not os.path.isfile(ROOTFOLDER+filePath+".hea"):
                # print("DOWNLOADING -- " + filePath )
                os.system(download_cmd +".hea") #fg; echo DOWNLOADED
            # print("DOWNLOAD COMPLETE -- " + filePath)
        except:
            continue
        # print(record_path)
        convertSingleFileToText(record_path+record)
        extractSingleAbpBeatFile(record_path+record)
        filesDownloaded.append(record)


    return filesDownloaded

def getListOfFiles(inFolder, ext):
    fileList = []
    for rootfolder, folder, filenames in os.walk(inFolder):
        for filename in [file for file in filenames if file.endswith(ext)]:
            fileList.append(os.path.join(filename[0:2],filename[0:7], filename[0:12]))
    return fileList


def convertSingleFileToText(record):
    fileThreshold = 17*1024

    filePath = ROOTFOLDER+record
    fileSize =  os.path.getsize(filePath+'.dat')
    if fileSize > fileThreshold:
            rdsamp_cmd = "rdsamp -r " + filePath +" -p > " + filePath + ".txt -s ABP PLETH -S ABP "
            if not IS_POSIX: 
                rdsamp_cmd = "wsl " + rdsamp_cmd
            os.system(rdsamp_cmd)

            move_cmd = "mv " + filePath +".txt " + TEXTDATAFOLDER
            if not IS_POSIX:
                move_cmd = "wsl "+ move_cmd
            os.system( move_cmd )



def convertFileListToText(dataFileList, numprocs):
    fileThreshold = 17*1024
    
    progress = 0
    for record in dataFileList:
        convertSingleFileToText(record)
        progress += 1
        printCollectiveProgress(progress/len(dataFileList), numprocs, "Conversion Progress")
    printCollectiveProgress(1, numprocs, "Conversion Progress")


def extractSingleAbpBeatFile(record):
    wabp_cmd = "wabp -r " + ROOTFOLDER + record
    if not IS_POSIX:
        wabp_cmd = "wsl "+ wabp_cmd
    os.system(wabp_cmd)

    wabp_cmd = "rdann -r " + ROOTFOLDER + record + " -a wabp >" + ABPANNFOLDER + record[11:]+"_abp.txt"
    if not IS_POSIX:
        wabp_cmd = "wsl "+ wabp_cmd
    os.system(wabp_cmd) 


def extractAbpBeatsList(fileList):
    # Generate wabp files and extract to text:
    progress = 0
    for f in fileList:
        extractSingleAbpBeatFile(f)
        progress += 1
        printCollectiveProgress(progress/len(fileList), numprocs, "ABP Extraction Progress")
    printCollectiveProgress(1, numprocs, "ABP Extraction Progress")



def printCollectiveProgress(numerator, denominator, message,):
    global comm
    coll_progress = comm.gather(numerator, root=0)
    if comm.Get_rank()!=0:
        return 0
    
    perc_progress = int(sum(coll_progress)*100//denominator)

    progress_text = "|"
    for i in range(perc_progress//5):
        progress_text += '\u2590'
    for i in range(perc_progress//5,20):
        progress_text += "-"
    progress_text += "|"
    print(" ",message,":", progress_text, perc_progress, "%",end='\r')



def printDownloadProgress(numFoldersExamined, numFoldersInRecord, numFilesDownloaded):
    global comm
    rank = comm.Get_rank()

    if rank != 0:
        return -1
    perc_progress = numFoldersExamined*100//numFoldersInRecord
    progress_text = "|"
    for i in range(perc_progress//5):
        progress_text += '\u2590'
    for i in range(perc_progress//5,20):
        progress_text += "-"
    progress_text += "|"
    print(" Download progress:", progress_text, perc_progress, "%",end='\r')



def fullConversionAndExtraction():
    datfileList = getListOfFiles(ROOTFOLDER, '.dat')
    numRecords = len(datfileList)//numprocs
    if rank == numprocs:
        datfileList = datfileList[rank*numRecords:]
    else:
        datfileList = datfileList[rank*numRecords:(rank+1)*numRecords]

    print("Converting to text") if rank==0 else 0
    convertFileListToText(datfileList,numprocs)

    print("\nExtracting ABP") if rank==0 else 0
    extractAbpBeatsList(datfileList)
    print("\nABP extraction complete") if rank==0 else 0
    print("Completed successfully") if rank ==0 else 0



if __name__ == '__main__':
    rank = comm.Get_rank()
    numprocs = comm.Get_size()

    print("Rank " + str(rank) + " starting...")

    if len(sys.argv) > 1:
        download_files_flag = int(sys.argv[1])
    else:
        download_files_flag = 1
    if len(sys.argv) > 2:
        start_download_idx = int(sys.argv[2])
    else:
        start_download_idx = 0
    if len(sys.argv) > 3:
        end_download_idx = int(sys.argv[3])
    else:
        end_download_idx = -1

    if rank == 0:
        if not os.path.isdir(TEXTDATAFOLDER):
            os.makedirs(TEXTDATAFOLDER)
        if not os.path.isdir(ABPANNFOLDER):
            os.makedirs(ABPANNFOLDER)

        allRecordPaths = getRecordList(ROOTURL)
        if end_download_idx > 0:
            allRecordPaths = allRecordPaths[start_download_idx:end_download_idx]
        else:
            allRecordPaths = allRecordPaths[start_download_idx:]
        amountToProc = len(allRecordPaths)//numprocs
        sendRecs = []

        allRecordPaths = getRecordList(ROOTURL)
        if end_download_idx > 0:
            allRecordPaths = allRecordPaths[start_download_idx:end_download_idx]
        else:
            allRecordPaths = allRecordPaths[start_download_idx:]
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

    if rank==0 and download_files_flag:
        with open(FILESDOWNLOADEDRECORD, "a") as file_obj:
            rec_update_str = str(start_download_idx)+"-" + str(end_download_idx) +" "+ str(datetime.datetime.now().strftime("%m/%d %H:%M:%S")) + " -- request \n"
            file_obj.write(rec_update_str)

    
    if download_files_flag!=0:
        print("\nBeginning downloads.") if rank==0 else 0
        scrape_mimic_list(myRecords, numprocs)
        print("\nDownloads complete.") if rank==0 else 0

    comm.Barrier()

    if rank==0 and download_files_flag:
        with open(FILESDOWNLOADEDRECORD, "a") as file_obj:
            rec_update_str = str(start_download_idx)+"-" + str(end_download_idx) +" "+ str(datetime.datetime.now().strftime("%m/%d %H:%M:%S")) + " -- complete \n"
            file_obj.write(rec_update_str)

    if not download_files_flag:
        fullConversionAndExtraction()


