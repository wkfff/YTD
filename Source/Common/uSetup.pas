(******************************************************************************

______________________________________________________________________________

YTD v1.00                                                    (c) 2009-12 Pepak
http://www.pepak.net/ytd                                  http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2009-12 Pepak (http://www.pepak.net)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Pepak nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEPAK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************)

unit uSetup;
{$INCLUDE 'ytd.inc'}

interface

const
  SETUP_PARAM_GUI {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--gui';
  SETUP_PARAM_SETUP {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--setup';
  SETUP_PARAM_UPGRADE {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--upgrade';
  SETUP_PARAM_UPGRADE_GUI {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--upgrade-gui';
  SETUP_PARAM_INSTALL {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--install';
  SETUP_PARAM_INSTALL_GUI {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--install-gui';
  SETUP_PARAM_INSTALL_LIBRARY {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--install-lib';
  SETUP_PARAM_UNINSTALL {$IFDEF MINIMIZESIZE} : string {$ENDIF} = '--uninstall';

implementation

end.
