from bs4 import BeautifulSoup
import requests
import os
import threading
import random
from multiprocessing.pool import Pool

ROOTURL = "https://physionet.org/files/mimic3wdb/1.0"
ROOTFOLDER = "./physionet.org/files/mimic3wdb/1.0/"
NUMTHREADS = 8
TEXTDATAFOLDER = './physionet.org/textdata/'
ABPANNFOLDER = "physionet.org/abp_ann/"
NUMPROCS = 4

IS_POSIX = os.name=='posix'

def getRecordList(url):
    #scrape root directory from physionet MIMICIII waveform (only)
    
    recordsRequest = requests.get(url + "/RECORDS-waveforms")

    #convert request item in Soup obj and into vector of string names
    soup = BeautifulSoup(recordsRequest.text, 'html.parser')

    #choose random selection of 100 records
    all_record_paths = random.sample(str(soup).splitlines(),100)
    # all_record_paths = str(soup).splitlines()[0:100]
    return all_record_paths


def scrape_mimic_list(record_paths):
    for record_path in record_paths:
        scrape_mimic(record_path=record_path)

def scrape_mimic(record_path):

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
        filePath = record_path + record
        download_cmd = "wget -r --no-parent " + ROOTURL + "/" + filePath;
        
        # For use with Windows (with WSL) add wsl add beginning of system command
        if not IS_POSIX: 
            download_cmd = "wsl "+ download_cmd

        #check if files have already been downloaded otherwise download them
        if not os.path.isfile(ROOTFOLDER+filePath+".dat"):
            print("DOWNLOADING -- " + filePath )
            os.system(download_cmd +".dat") #fg; echo DOWNLOADED
        else:
            print("ALREADY DOWNLOADED " + filePath+".dat")
        if not os.path.isfile(ROOTFOLDER+filePath+".hea"):
            print("DOWNLOADING -- " + filePath )
            os.system(download_cmd +".hea") #fg; echo DOWNLOADED
        else:
            print("ALREADY DOWNLOADED " + filePath+".hea")
        print("DOWNLOAD COMPLETE -- " + filePath)

def getListOfFiles(inFolder, ext):
    fileList = []
    for rootfolder, folder, filenames in os.walk(inFolder):
        for filename in [file for file in filenames if file.endswith(ext)]:
            fileList.append(os.path.join(filename[0:2],filename[0:7], filename[0:12]))
    return fileList

def convertToText(dataFileList):
    fileThreshold = 17*1024
    for record in dataFileList:
        filePath = ROOTFOLDER+record
        fileSize =  os.path.getsize(filePath+'.dat')
        if fileSize > fileThreshold:
            # Convert to TXT
            #rdsamp: to text is -p > newName.txt
            # -s : signal list is ABP, PLETH in that order => output cols will be TIME-ABP-PLETH
            # -S : search for first valid time for ABP
            rdsamp_cmd = "rdsamp -r " + filePath +" -p > " + filePath + ".txt -s ABP PLETH -S ABP"
            if not IS_POSIX: 
                rdsamp_cmd = "wsl " + rdsamp_cmd

            print('CONVERTING TO TXT -- ' + filePath)
            print(rdsamp_cmd)
            os.system(rdsamp_cmd)
            print('CONVERTING TO TXT COMPLETE -- ' + filePath)
            # move converted files to new folder
        
            move_cmd = "mv " + filePath +".txt " + TEXTDATAFOLDER
            if not IS_POSIX:
                move_cmd = "wsl "+ move_cmd
            print(move_cmd)
            os.system( move_cmd )

def extractAbpBeats(fileList):
    # Generate wabp files and extract to text:
  
    if not os.path.isdir(ABPANNFOLDER):
        os.mkdir(ABPANNFOLDER)

    for f in fileList:
        print('EXTRACTING ABP -- ' + f)
        wabp_cmd = "wabp -r " + ROOTFOLDER + f
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd)
        wabp_cmd = "rdann -r " + ROOTFOLDER + f + " -a wabp >" + ABPANNFOLDER + f[11:]+"_abp.txt"
        if not IS_POSIX:
            wabp_cmd = "wsl "+ wabp_cmd
        os.system(wabp_cmd) 
        print('ABP EXTRACTION COMPLETE -- ' + f)

if __name__ == '__main__':

    allRecordPaths = getRecordList(ROOTURL)

    pool = Pool(NUMPROCS)
   
    pool.map(scrape_mimic, allRecordPaths)
    
    datfileList = getListOfFiles(ROOTFOLDER, '.dat')
    
    pool.map(convertToText, datfileList)

    txtFileList = getListOfFiles(TEXTDATAFOLDER, '.txt')
    pool.map(extractAbpBeats, txtFileList)