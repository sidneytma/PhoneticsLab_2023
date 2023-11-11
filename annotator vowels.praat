procedure getTextGrid: .wav$

    .path_temp$ = replace$: .wav$, ".wav", ".TextGrid", 0
	.path$ = replace$: .path_temp$, "stimuli", "stimulus_textgrids", 0

	.basename_temp$ = replace$: .path$, "/Users/sidneyma/Desktop/school/lign199/stimulus_textgrids/", "", 0
	.basename$ = replace$: .basename_temp$, ".TextGrid", "", 0
	writeInfoLine: .basename$


    if !fileReadable: .path$
        .textgrid = To TextGrid: tiers$, point_tiers$


    elif if_TextGrid_already_exists == 2
        .textgrid = To TextGrid: tiers$, point_tiers$
        .default$ = mid$: .path$, rindex (.path$, "/") + 1, length (.path$)
        .default$ = replace$: .default$, ".wav", ".TextGrid", 1

        .path$ = chooseWriteFile$: "TextGrid already exists in folder. 
        ... Choose where to save the new TextGrid.", .default$

    elif if_TextGrid_already_exists == 3
        .textgrid = Read from file: .path$

    endif

endproc

procedure getFiles: .dir$, .ext$
    .obj = Create Strings as file list: "files", .dir$ + "/*" + .ext$
    .length = Get number of strings

    for .i to .length
        .fname$ = Get string: .i
        .files$ [.i] = .dir$ + "/" + .fname$

    endfor

    removeObject: .obj

endproc

## MAIN
directory$ = chooseDirectory$: "Choose a directory with wav files to annotate."

form Arguments
    sentence Interval_tiers vowel
    sentence Point_tiers 
    optionmenu If_TextGrid_already_exists: 1
        option skip the wav file
        option create a new TextGrid
        option open the existing TextGrid
    comment Press OK to choose the directory of wav files to annotate.
endform

tiers$ = interval_tiers$ + " " + point_tiers$
@getFiles: directory$, ".wav"

for i to getFiles.length
    wav = Read from file: getFiles.files$ [i]

    @getTextGrid: getFiles.files$ [i]

    if !fileReadable (getTextGrid.path$) or if_TextGrid_already_exists > 1
        selectObject: wav, getTextGrid.textgrid

        View & Edit

        beginPause: "Annotation"
            comment: "Press OK when done to save."

        endPause: "OK", 0

        selectObject: getTextGrid.textgrid
        Save as text file: getTextGrid.path$

        removeObject: getTextGrid.textgrid

    endif

    removeObject: wav
endfor