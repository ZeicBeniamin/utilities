# utilities
Useful files and code excerpts
###### video_converter.sh
Script that runs three separate ffmpeg threads for converting videos to lower bitrates. Ffmpeg is used in conjunction with NVIDIA hardware accelerators (provided through the CUDA toolkit). I used the script for converting the recordings of online lectures that had quite large bitrate values, which made file storage a problem.
