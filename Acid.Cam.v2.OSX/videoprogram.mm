/*
 * Software written by Jared Bruni https://github.com/lostjared
 
 This software is dedicated to all the people that experience mental illness.
 
 Website: http://lostsidedead.com
 YouTube: http://youtube.com/LostSideDead
 Instagram: http://instagram.com/lostsidedead
 Twitter: http://twitter.com/jaredbruni
 Facebook: http://facebook.com/LostSideDead0x
 
 You can use this program free of charge and redistrubute it online as long
 as you do not charge anything for this program. This program is meant to be
 100% free.
 
 BSD 2-Clause License
 
 Copyright (c) 2020, Jared Bruni
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */


// This file contains the functions to Start/Stop the capture/recording devices
#import"AC_Controller.h"
#include<fstream>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#undef check
#include"videocapture.h"

extern FILE *fptr;

std::string input_, output_;
// Variable definiton
unsigned int int_Seed = (unsigned int)(time(0));
bool breakProgram = false, programRunning = false, stopProgram = false;
unsigned long total_frames = 0;
void ProcFrame(cv::Mat &frame);
std::unique_ptr<cv::VideoCapture> capture_camera(new cv::VideoCapture());
std::unique_ptr<cv::VideoCapture> capture_video(new cv::VideoCapture());
long frame_cnt, key;
long video_total_frames = 0;
NSTimer *renderTimer;
std::ostringstream sout;
std::unique_ptr<cv::VideoWriter> writer;
unsigned long file_size;
std::string add_path;
std::string input_name = "";
bool copy_sound = false;
int output_Type = 0;
std::string ffmpeg_string_path;
// Stop the OpenCV capture
void stopCV() {
    if(camera_active == true) {
        camera_active = false;
        ac::release_all_objects();
        sout << "Camera Mode: All stored frames released\n";
        return;
    }
    // if timer is valid
    if(renderTimer != nil && renderTimer.valid) {
        // stop timer
        if(fptr != 0)
              pclose(fptr);
        
        [renderTimer invalidate];
        renderTimer = nil;
        // destroy the OpenCV Windows
        cv::destroyWindow("Acid Cam v2");
        cv::destroyWindow("Controls");
        // if recording clean up and release the writer
        if(!ac::noRecord) {
            writer->release();
            if(camera_mode == 1 && copy_sound == true) {
                std::stringstream stream;
                auto pos = ac::fileName.rfind("_.");
                if(pos != std::string::npos) {
                    std::string file_n = ac::fileName.substr(0, pos);
                    stream << file_n << ".mp4";
                    mux_audio(output_.c_str(), input_.c_str(), stream.str().c_str());
                    sout << "Successfully Wrote Video File to: " << stream.str() << "\n";
                    //std::remove(ac::fileName.c_str());
                }
            } else {
                sout << "Wrote to Video File: " << ac::fileName << "\n";
            }
        }
        sout << frame_proc << " Total frames\n";
        if(camera_mode == 1) sout << (elapsed_counter/ac::fps) << " Seconds\n";
        else if(camera_mode == 0) sout << (frame_proc/ac::fps) << " Seconds\n";
        // flush to log
        setEnabledProg();
        capture->release();
        [controller stopCV_prog];
        int allocated_ = ac::getCurrentAllocatedFrames();
        ac::release_all_objects();
        sout << allocated_ << " stored frames released\n";
        flushToLog(sout);
        if(breakProgram == true) {
            [NSApp terminate:nil];
        }
    }
}

// program function to start process
int program_main(double fps_value, BOOL output, int resize_w, int resize_h, BOOL show, bool fps_on, double fps_val, bool u4k, int outputType, std::string input_file, bool noRecord, std::string outputFileName, int capture_width, int capture_height, int capture_device, long frame_countx, float pass2_alpha, std::string file_path) {
    programRunning = true;
    input_ = "";
    output_ = "";
    sout << "Acid Cam v" << ac::version << " Initialized ..\n" << ac::getFilterCount() << " Filters Loaded...\n";
    sout << "OpenCL Enabled: " << ((ac::OpenCL_Enabled() == true) ? "Yes" : "No") << "\n";
    add_path="default";
    input_name = input_file;
    srand(static_cast<unsigned int>(time(0)));
    ac::translation_variable = 0.01;
    ac::tr = ac::translation_variable;
    ac::fileName = file_path+outputFileName;
    ac::noRecord = noRecord;
    ac::pass2_alpha = pass2_alpha;
    unsigned int seed = int_Seed;
    srand(seed);
    add_path = file_path;
    stopProgram = false;
    ac::tr =  0.3;
    ac::fps = 29.97;
    file_size = 0;
    video_total_frames = 0;
    output_Type = outputType;
    writer.reset(new cv::VideoWriter());
    try {
        // open either camera or video file
        if(camera_mode == 0 /*&& capture->isOpened() == false*/) {
            capture->open(capture_device);
            capture->set(cv::CAP_PROP_FPS, fps_value);
        }
        else if(camera_mode == 1)  {
            capture->open(input_file);
            input_ = input_file;
            total_frames = capture->get(cv::CAP_PROP_FRAME_COUNT);
        }
        // check that it is opened
        if (!capture->isOpened()) {
            std::cerr << "Error could not open Camera device..\n";
            return -1;
        } else
            sout << "Acid Cam Capture device [" << ((camera_mode == 0) ? "Camera" : "Video") << "] opened..\n";
        
        if(camera_mode == 1)
            sout << "Opening Video File: " << input_file << "\n";
        
        int aw = capture->get(cv::CAP_PROP_FRAME_WIDTH);
        int ah = capture->get(cv::CAP_PROP_FRAME_HEIGHT);
        if(u4k && aw != capture_width && ah != capture_height)
            sout << "Resolution Scaled to " << capture_width << "x" << capture_height << "\n";
        else
            sout << "Resolution: " << aw << "x" << ah << "\n";
        
        ac::fps = capture->get(cv::CAP_PROP_FPS);
        if(ac::fps_force == false && input_file.size() != 0) ac::fps = capture->get(cv::CAP_PROP_FPS);
        if(ac::fps <= 0 || ac::fps > 60) ac::fps = 30;
        sout << "FPS: " << ac::fps << "\n";
        cv::Size frameSize = cv::Size(aw, ah); //frame.size();
        ac::resolution = frameSize;
        if(camera_mode == 0 && capture_width != 0 && capture_height != 0) {
            capture->set(cv::CAP_PROP_FRAME_WIDTH, capture_width);
            capture->set(cv::CAP_PROP_FRAME_HEIGHT, capture_height);
            capture_width = capture->get(cv::CAP_PROP_FRAME_WIDTH);
            capture_height = capture->get(cv::CAP_PROP_FRAME_HEIGHT);
            if(u4k)
                sout << "Resolution upsacled to " << capture_width << "x" << capture_height << "\n";
            else
                sout << "Resolution set to " << capture_width << "x" << capture_height << "\n";
            frameSize = cv::Size(capture_width, capture_height);
        }
        std::string output_format;
        setSliders(total_frames);
        bool opened = false;
        // if recording open the writer object with desired codec
        if(ac::noRecord == false) {
            cv::Size s4k = cv::Size(capture_width, capture_height);
            if(u4k ==false) {
                s4k = frameSize;
            }
            if(camera_mode == 0 && fps_on == true) {
                ac::fps = fps_val;
                sout << "Forced Frame Rate: " << fps_val << "\n";
            }
            std::ostringstream fs;
            static unsigned int counter = 0;
            if(!noRecord) ++counter;
            std::string sound_prefix;
            if(outputType == 0)
                output_format = "MPEG-4";
            else if(outputType == 1)
                output_format = "AVC";
            else if(output_Type == 2)
                output_format = "HEVC";
            
            if(outputType == 0) {
                if(camera_mode == 1 && copy_sound == true) sound_prefix = "_";
                fs << ac::fileName << output_format << "-" << s4k.width << "x" << s4k.height << "p" << std::fixed << std::setprecision(2) << ac::fps  << ".AC2.Output." << counter << sound_prefix << ".mp4";
                ac::fileName = fs.str();
                opened = writer->open(ac::fileName, cv::VideoWriter::fourcc('m','p','4','v'),  ac::fps, s4k, true);
            }
            else if(outputType == 1) {
                if(camera_mode == 1 && copy_sound == true) sound_prefix = "_";
                fs << ac::fileName << output_format << "-" << s4k.width << "x" << s4k.height << "p" << std::fixed << std::setprecision(2) << ac::fps << ".AC2.Output." << counter << sound_prefix << ".mp4";
                ac::fileName = fs.str();
                //opened = writer->open(ac::fileName, cv::VideoWriter::fourcc('a','v','c','1'),  ac::fps, s4k, true);
                std::ostringstream stream;
                stream << s4k.width << "x" << s4k.height;
                std::string res = stream.str();
                stream.str("");
                stream << ac::fps;
                std::string f = stream.str();
                if(camera_mode == 1)
                    fptr = open_ffmpeg(ac::fileName.c_str(),"libx264",res.c_str(), res.c_str(), f.c_str(), crf.c_str());
                else
                    opened = writer->open(ac::fileName, cv::VideoWriter::fourcc('a','v','c','1'),  ac::fps, s4k, true);

            } else if(outputType == 2) {
                if(camera_mode == 1 && copy_sound == true) sound_prefix = "_";
                fs << ac::fileName << output_format << "-" << s4k.width << "x" << s4k.height << "p" << std::fixed << std::setprecision(2) << ac::fps  << ".AC2.Output." << counter << sound_prefix << ".mp4";
                ac::fileName = fs.str();
                //opened = writer->open(ac::fileName, cv::VideoWriter::fourcc('h','v','c','1'),  ac::fps, s4k, true);
                std::ostringstream stream;
                stream << s4k.width << "x" << s4k.height;
                std::string res = stream.str();
                stream.str("");
                stream << ac::fps;
                std::string f = stream.str();
                if(camera_mode == 1)
                    fptr = open_ffmpeg(ac::fileName.c_str(),"libx265",res.c_str(), res.c_str(), f.c_str(), crf.c_str());
                else
                    opened = writer->open(ac::fileName, cv::VideoWriter::fourcc('h','v','c','1'),  ac::fps, s4k, true);
            }
            if(fptr != 0 || writer->isOpened()) {
                output_ = ac::fileName;
            }
            // if writer is not opened exit
            if(fptr == 0 && (writer->isOpened() == false || opened == false)) {
                sout << "Error video file could not be created.\n";
                _NSRunAlertPanel(@"Error", @"Video file could not be created Output directory exisit?\n", @"Close", nil, nil);
                return -1;
            }
            if(blend_image.empty()) {
                blend_image.create(frameSize, CV_8UC3);
                ac::fillRect(blend_image, ac::Rect(0, 0, blend_image.cols, blend_image.rows), cv::Vec3b(0,0,0));
            }
        }
        // output wehther recording or not
        if(ac::noRecord == false)
            sout << "Now recording .. format " << output_format << " \n";
        else
            sout << "Recording disabled ..\n";
        
        // create the window and show initial frame
        if(output == YES) {
            NSRect screen = [[NSScreen mainScreen] frame];
            cv::namedWindow("Acid Cam v2", cv::WINDOW_NORMAL | cv::WINDOW_GUI_EXPANDED);
            if(u4k && capture_width >= screen.size.width && capture_height >= screen.size.height) {
                rc.size.width = screen.size.width;
                rc.size.height = screen.size.height;
                resize_value = true;
                cv::resizeWindow("Acid Cam v2", rc.size.width, rc.size.height);
            }
            else if(u4k == false && frameSize.width > screen.size.width && frameSize.height > screen.size.height) {
                rc.size.width = screen.size.width;
                rc.size.height = screen.size.height;
                resize_value = true;
                cv::resizeWindow("Acid Cam v2", rc.size.width, rc.size.height);
            } else {
                if(u4k) {
                    rc.size.width = (double) capture_width;
                    rc.size.height = (double) capture_height;
                    resize_value = true;
                } else {
                    rc.size.width = aw;
                    rc.size.height = ah;
                    resize_value = false;
                }
            }
        }
        if(show == NO) {
            cv::Mat _bg;
            _bg.create(cv::Size(rc.size.width, rc.size.height), CV_8UC3);
            ac::fillRect(_bg,ac::Rect(0, 0, _bg.cols, _bg.rows), cv::Vec3b(0,0,0));
            if(output == YES && _bg.size().width > 0 && _bg.size().height > 0) cv::imshow("Acid Cam v2", _bg);
        }
        // flush to log
        flushToLog(sout);
        frame_cnt = 0;
        frame_proc = 0;
        return 0;
    }
    // standard exceptions handled here
    catch(std::exception &e) {
        std::cerr << e.what() << " was thrown!\n";
    }
    // unknown exceptions handled here
    catch(...) {
        std::cerr << "Unknown error thrown.\n";
    }
    return 0;
}
// string stream for output
std::ostringstream strout;
// jump to frame in video
void jumptoFrame(BOOL showJump, long frame) {
    capture->set(cv::CAP_PROP_POS_FRAMES,frame);
    cv::Mat pos;
    capture->read(pos);
    capture->set(cv::CAP_PROP_POS_FRAMES,frame);
    if(showJump == NO) {
        if(capture->isOpened() && pos.size().width > 0 && pos.size().height > 0) {
                cv::imshow("Acid Cam v2", pos);
        } else {
            std::ostringstream stream;
            stream << "Error: File format does not allow Skipping to frames. Video will now exit.\n";
            flushToLog(stream);
        }
    }
    frame_cnt = frame;
}
