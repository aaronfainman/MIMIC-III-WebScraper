#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>

using namespace std;


bool matchStringInFile(ifstream& file, string& match);

int main(){

    auto ROOTURL = string{"https://physionet.org/files/mimic3wdb/1.0"};

    auto ROOTCMD = "wget -r -c " + ROOTURL;

    auto LOCALPATH = string{"./physionet.org/files/mimic3wdb/1.0"};

    //DOWNLOAD WAVEFORM RECORDS FILE
    auto cmd = string{ROOTCMD+"/RECORDS-waveforms"};
    system( cmd.c_str() );

    //file to log all the useful records (ie. containing PLETH + ABP)
    ofstream usefuls_file;
    usefuls_file.open("useful_records.txt");

    //file to read the waveform records
    ifstream record_file;
    record_file.open(LOCALPATH+string{"/RECORDS-waveforms"});

    //file to read layout header file for each record -- used to check if record
    //      contains ABP and PLETH data
    ifstream layout_file;


    auto record_path = string{""};
    auto record_name = string{""};

    int idx = 0;

    while(record_file.good())
    {
        getline(record_file, record_path);
        record_name = record_path.substr(3,7);

        cmd = string{ROOTCMD+"/" + record_path + record_name + "_layout.hea"};
        system( cmd.c_str() );

        layout_file.open(LOCALPATH +string{"/"}+ record_path + record_name + string{"_layout.hea"});
        // auto temp = string{""};
        // getline(layout_file, temp);

        auto match_term = string{"AVR"};
        auto match = matchStringInFile(layout_file, match_term);
        cout << LOCALPATH +string{"/"}+ record_path + record_name + string{"_layout.hea"} << "  --  " << match << endl;

        layout_file.close();

        if(idx++ == 5) break;

        // cout << LOCALPATH +string{"/"}+ record_path + record_name + string{"_layout.hea"} << "---- " << temp << endl;
    }

    record_file.close();
    usefuls_file.close();


    return 0;
}




bool matchStringInFile(ifstream& file, string& match)
{
    auto line = string{""};
    while(file.good())
    {
        getline(file, line);
        if( line.find(match) != string::npos ) return true;
    }

    return false;
}