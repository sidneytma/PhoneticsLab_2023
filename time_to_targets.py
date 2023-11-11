# Script to get the durations of annotated textgrids and save them to a file.

import pandas as pd

import os
import praatio
from praatio import tgio

# Get the duration of a textgrid, given the filename and annotation name.
def get_duration(textgrid_path, annotation):
    
    tg = tgio.openTextgrid(textgrid_path)
    first_tier = tg.tierDict[tg.tierNameList[0]]
    
    for entry in first_tier.entryList:
        start_time, end_time, label = entry
        if label == annotation:
            return round(end_time - start_time, 3)
        

# Set the directory
dir_name = '/Users/sidneyma/Desktop/school/lign199'

# Name the output file 'durations.txt'
text_file_path = os.path.join(dir_name, 'durations.txt')

# Set the columns in this file
with open(text_file_path, 'w') as file:
    file.write('file,time_to_target\n')

# Set the directory of the stimulus textgrids
dir_name = os.path.join(dir_name, 'stimulus_textgrids')

# Main loop
for file in os.listdir(dir_name):
    if file.endswith('.TextGrid'):
        file_path = os.path.join(dir_name, file)
        annotation = file.replace('.TextGrid', '')
        duration = get_duration(file_path, annotation)
        
        with open(text_file_path, 'a') as txt_file:
            txt_file.write(f"{annotation}, {duration}\n")