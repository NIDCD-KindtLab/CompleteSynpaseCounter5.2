// Functions:
//   built for generating neuromast masks
//   go though all czi 3D image stacks in the folder
//   provide Z-projection images for users to draw a single roi
//   save the binary mask of the roi
//
// Depends on plugin Masks From ROIs : https://sites.imagej.net/MasksfromRois/
// 20230517 Leiz


// **************************************************************
// **************************************************************

//  Set the channel asignment
    chArr =   newArray( "_hc",    "_ctbp",    "_mag");
    chColor = newArray("Grays", "Magenta",   "Green");
    
//***************************************************************    
//***************************************************************



inDir = getDirectory("--> INPUT: Choose Directory <--");
outDir = getDirectory("--> OUTPUT: Choose Directory for TIFF Output <--");
inList = getFileList(inDir);
list = getFromFileList("czi", inList);  // select dirs only
Array.sort(list);
nl = list.length;

// Checkpoint: get list of dirs
print("Below is a list of files to be processeded:");
printArray(list); // Implemented below
print("Result save to:");
print(outDir);
tag = "_hc_msk";

outChPrj = outDir + File.separator + "chPrj" + File.separator;
if (!File.exists(outChPrj)) {
    File.makeDirectory(outChPrj);
}
// data processing
setBatchMode(false);
roiManager("show none"); 
roiManager("reset"); 
for (i=0; i<nl; i++) 
{
  inFullname = inDir + list[i];
  sampleID = substring(list[i],0, lengthOf(list[i])-4);
  outFullname = outDir + sampleID + tag + ".tif";
//  txt = substring(list[i],0, lengthOf(list[i])-4);
  print("Saving(",(i+1),"/",list.length,")...",list[i]); // Checkpoint: Indicating progress

  open(inFullname);
  rename("Current");
  run("Duplicate...", "title=Current1 duplicate");
  run("Split Channels");
  for (j=1;j<4;j++){
  	curPrj = outChPrj + sampleID + chArr[j-1] + "Prj.tif";
  	if(!File.exists(curPrj)){
  	selectWindow("C" + j + "-Current1");
    run("Subtract Background...", "rolling=50 stack");
    selectWindow("C" + j + "-Current1");
    run("Z Project...", "projection=[Max Intensity]");
    saveAs("Tiff", curPrj );
    selectWindow("C" + j + "-Current1"); close();
  	}
  }	
  selectWindow("Current");	
  run("Z Project...", "projection=[Max Intensity]");
  rename("zpj");
  selectWindow("zpj");
  Stack.setDisplayMode("composite");
  //  Stack.setActiveChannels("110");
//  run("8-bit");
  Stack.setChannel(1)
  run("Enhance Contrast", "saturated=0.02");
  run(chColor[0]);
  Stack.setChannel(2)
  run(chColor[1]);
  run("Enhance Contrast", "saturated=0.02");
  Stack.setChannel(3)
  run(chColor[2]);
  run("Enhance Contrast", "saturated=0.35");  
  run("Flatten");
  
  
   
  // Prompt the user to draw an ROI
  run("ROI Manager...");
  roiManager("reset");
  run("Show All");
  selectWindow("Current");	
  waitForUser("Draw ROI, then hit OK");   
  roiManager("Add");
    
  run("Binary (0-255) mask(s) from Roi(s)", "show_mask(s) save_in=[] suffix=[] save_mask_as=tif rm=[RoiManager[size=1, visible=true]]");
  saveAs("Tiff", outFullname);
  roiManager("reset");
  run("Close All");
  print("...done."); //Checkpoint: Done one.
}

setBatchMode("exit and display");
print("--- All Done ---");

// --- Main procedure end ---

////
function getFromFileList(ext, fileList)
{
  // Select from fileList array the filenames with specified extension
  // and return a new array containing only the selected ones.
  selectedFileList = newArray(fileList.length);
  selectedDirList = newArray(fileList.length);
  ext = toLowerCase(ext);
  j = 0;
  iDir = 0;
  for (i=0; i<fileList.length; i++)
    {
      extHere = toLowerCase(getExtension(fileList[i]));
      if (endsWith(fileList[i], "/"))
        {
      	  selectedDirList[iDir] = fileList[i];
      	  iDir++;
        }
      else if (extHere == ext)
        {
          selectedFileList[j] = fileList[i];
          j++;
        }
    }
    
  selectedFileList = Array.trim(selectedFileList, j);
  selectedDirList = Array.trim(selectedDirList, iDir);
  if (ext == "")
    {
    	return selectedDirList;
    }
  else 
    {
    	return selectedFileList;
    }
}

/////
function printArray(array)
{ 
  // Print array elements recursively 
  for (i=0; i<array.length; i++)
    print(array[i]);
}

////
function getExtension(filename)
{
  ext = substring( filename, lastIndexOf(filename, ".") + 1 );
  return ext;
}