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
    
    progress = 0
    for record in dataFileList:
        filePath = ROOTFOLDER+record
        fileSize =  os.path.getsize(filePath+'.dat')
        progress += 1
        printCollectiveProgress(progress/len(datfileList), numprocs, "Conversion Progress")
        if fileSize > fileThreshold:
            # Convert to TXT
            #rdsamp: to text is -p > newName.txt
            # -s : signal list is ABP, PLETH in that order => output cols will be TIME-ABP-PLETH
            # -S : search for first valid time for ABP
            # rdsamp_cmd = "taskkill /im rdsamp -r " + filePath +" -p > " + filePath + ".txt -s ABP PLETH -S ABP /f >/dev/null 2>&1"
            rdsamp_cmd = "rdsamp -r " + filePath +" -p > " + filePath + ".txt -s ABP PLETH -S ABP "
            if not IS_POSIX: 
                rdsamp_cmd = "wsl " + rdsamp_cmd

            # print('CONVERTING TO TXT -- ' + filePath)
            # print(rdsamp_cmd)
            os.system(rdsamp_cmd)
            # print('CONVERTING TO TXT COMPLETE -- ' + filePath)
            # move converted files to new folder
        
            move_cmd = "mv " + filePath +".txt " + TEXTDATAFOLDER
            if not IS_POSIX:
                move_cmd = "wsl "+ move_cmd
            # print(move_cmd)
            os.system( move_cmd )
    printCollectiveProgress(1, numprocs, "Conversion Progress")
        

def extractAbpBeats(fileList):
    # Generate wabp files and extract to text:

    progress = 0
    for f in fileList:
        # print('EXTRACTING ABP -- ' + f)
        # wabp_cmd = "taskkill /im  wabp -r " + ROOTFOLDER + f + " /f >null 2>&1"
        wabp_cmd = "wabp -r " + ROOTFOLDER + f
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd)
        #output from command suppressed using: taskkill /im <rdann command> /f >null 2>&1
        # wabp_cmd = "taskkill /im rdann -r " + ROOTFOLDER + f + " -a wabp >" + ABPANNFOLDER + f[11:]+"_abp.txt /f >null 2>&1"
        wabp_cmd = "rdann -r " + ROOTFOLDER + f + " -a wabp >" + ABPANNFOLDER + f[11:]+"_abp.txt"
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd) 
        
        progress += 1
        printCollectiveProgress(progress/len(fileList), numprocs, "ABP Extraction Progress")
    printCollectiveProgress(1, numprocs, "ABP Extraction Progress")
        # print('ABP EXTRACTION COMPLETE -- ' + f)


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


coll_folders_examined = [0 for i in range(0, comm.Get_size())]
coll_folders_required = [0 for i in range(0, comm.Get_size())]
coll_files_downloaded = [0 for i in range(0, comm.Get_size())]
def printDownloadProgress(numFoldersExamined, numFoldersInRecord, numFilesDownloaded):
    global comm
    # global coll_folders_required
    # global coll_folders_examined
    # global coll_files_downloaded
    
    # numprocs = comm.Get_size()
    rank = comm.Get_rank()

    # if rank!=0:
    #     req_examined = comm.isend(numFoldersExamined, dest=0, tag=0)
    #     req_examined.wait()
    #     req_required = comm.isend(numFoldersInRecord, dest=0, tag=1)
    #     req_required.wait()
    #     req_downloaded = comm.isend(numFilesDownloaded, dest=0, tag=2)
    #     req_downloaded.wait()
    #     return 0

    # for src in range(1,numprocs):
    #     req_examined = comm.irecv(source=src, tag=0)
    #     temp_ex =  req_examined.wait() 
    #     req_required = comm.irecv(source=src, tag=1)
    #     temp_req = req_required.wait()
    #     req_downloaded = comm.irecv(source=src, tag=2)
    #     temp_down = req_downloaded.wait()
    #     coll_folders_examined[src] = temp_ex if temp_ex != 0 else coll_folders_examined[src]
    #     coll_folders_required[src] = temp_req if temp_req != 0 else coll_folders_required[src]
    #     coll_files_downloaded[src] = temp_down if temp_down != 0 else coll_files_downloaded[src]
    
    # coll_folders_examined[0] = numFoldersExamined
    # coll_folders_required[0] = numFoldersInRecord
    # coll_files_downloaded[0] = numFilesDownloaded

    # num_folders_examined = sum(coll_folders_examined)
    # num_folders_required = sum(coll_folders_required)
    # num_files_downloaded = sum(coll_files_downloaded)

    # perc_progress = num_folders_examined//num_folders_required*100
    if rank != 0:
        return -1
    # ************* currently just use rank 0's progress as approximation for download progress
    perc_progress = numFoldersExamined*100//numFoldersInRecord
    progress_text = "|"
    for i in range(perc_progress//5):
        progress_text += '\u2590'
    for i in range(perc_progress//5,20):
        progress_text += "-"
    progress_text += "|"

    # print(" Download Progress: ", progress_text, " ", num_folders_examined, "/", num_folders_required, " folders examined. ",num_files_downloaded, " files downloaded",end='\r\r')
    print(" Download progress:", progress_text, perc_progress, "%",end='\r')



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
            rec_update_str = str(start_download_idx)+"-" + str(end_download_idx) +" "+ str(datetime.datetime.now().day) + "\\" + str(datetime.datetime.now().month)+ " -- request \n"
            file_obj.write(rec_update_str)

    
    if download_files_flag!=0:
        print("\nBeginning downloads.") if rank==0 else 0
        scrape_mimic_list(myRecords, numprocs)
        print("\nDownloads complete.") if rank==0 else 0

    if rank==0 and download_files_flag:
        with open(FILESDOWNLOADEDRECORD, "a") as file_obj:
            rec_update_str = str(start_download_idx)+"-" + str(end_download_idx) +" "+ str(datetime.datetime.now().day) + "\\" + str(datetime.datetime.now().month)+ " -- complete \n"
            file_obj.write(rec_update_str)

    comm.Barrier()


    
    datfileList = getListOfFiles(ROOTFOLDER, '.dat')
    numRecords = len(datfileList)//numprocs
    if rank == numprocs:
        datfileList = datfileList[rank*numRecords:]
    else:
        datfileList = datfileList[rank*numRecords:(rank+1)*numRecords]

    print("Converting to text") if rank==0 else 0
    convertToText(datfileList,numprocs)

    print("\nExtracting ABP") if rank==0 else 0
    extractAbpBeats(datfileList)
    print("\nABP extraction complete") if rank==0 else 0
    print("Completed successfully") if rank ==0 else 0

