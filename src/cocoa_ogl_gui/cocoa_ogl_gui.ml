(** Copyright (C) 2018,  Gavin J Stark.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @file          cocoal_ogl_gui.ml
 * @brief         Cocoa input/output for OpenGl framework library
 *
 *)
open Ogl_gui
open Cocoa_ogl_gui_c
open Batteries

module NSApplication=Cocoa_ogl_gui_c.NSApplication

type t_window_handle  = Ogl_gui.Types.t_window_handle
type 'a t_ogl_result  = 'a Ogl_gui.Utils.ogl_result
(*a Support *)
let trace pos = 
    let (a,b,c,d) = pos in
    Printf.printf "trace:%s:%d:%d:%d\n%!" a b c d

(*a Cocoa OpenGL application - runs an Ogl_app *)
module Cocoa_ogl_app = struct
    (*t t_win - structure for a window *)
    type t_win = {
        wh : t_window_handle;
        mutable ns_win : NSApplication.t_ns_window option;
      }

    (*t type of module - Cocoa window and window's OpenGL context *)
    type t = {
        mutable ns_app : NSApplication.t option;
        ogl_app : Ogl_gui.Types.t_ogl_app ;
        ogl_root_dir : string;
        mutable win_ctxs :  (t_window_handle * t_win) list;
        start_time : int;
      }

    (*f ns_app *)
    let ns_app t = Option.get t.ns_app

    (*f ogl_app *)
    let ogl_app t = t.ogl_app

    (*f ogl_root_dir *)
    let ogl_root_dir t = t.ogl_root_dir

    (*f create *)
    let create ogl_root_dir ogl_app = 
      let t = {
          ns_app = None;
          ogl_root_dir;
          ogl_app;
          win_ctxs = [];
          start_time = 0;
        } in
      Printf.printf "Creating\n";
      let ns_app = NSApplication.create t in
      Printf.printf "Created NSApplication\n";
      t.ns_app <- Some ns_app;
      t

    (*f create_window *)
    let create_window ?width:(width=640) ?height:(height=480) ?title:(title="banana") t wh :(t_window_handle t_ogl_result) =
      let win = { wh; ns_win=None } in
      let ns_win = NSApplication.create_window (ns_app t) win in
      win.ns_win <- Some ns_win;
      t.win_ctxs <- (wh, win) :: t.win_ctxs;
      Ok wh

    (*f init *)
    let init t : unit =
  trace __POS__;
      (*Sdl.init Sdl.Init.(video + timer)
     >>>= fun () ->*)
      let cwin ~width ~height ~title = create_window ~width:width ~height:height ~title:title t in
      ignore ((ogl_app t)#set_create_window cwin);
      ignore ((ogl_app t)#create (ogl_root_dir t));
  trace __POS__;
      ()

    (*f destroy *)
    let destroy t =
      ignore ((ogl_app t)#destroy);
      Printf.printf "Destroy cocoa app\n"

    (*f Reshape/draw *)
    let reshape_draw t w r width height =
  trace __POS__;
      match r with
      | NSApplication.Resize ->
          (ogl_app t)#reshape (w.wh) width height
      | NSApplication.Draw   ->
          (ogl_app t)#draw (w.wh)

    (*f run *)
    let run t : 'a t_ogl_result = 
  trace __POS__;
      NSApplication.set_callback_create       (ns_app t) (Some init);
      NSApplication.set_callback_reshape_draw (ns_app t) (Some reshape_draw);
      NSApplication.set_callback_destroy      (ns_app t) (Some destroy);
      NSApplication.run (ns_app t);
      Ok ()

    (*f All done *)
end

(*a Toplevel *)
(*f run_app *)
let run_app ?width:(width=640) ?height:(height=400) ?title:(title="Untitled") ?ogl_root_dir:(ogl_root_dir="") (ogl_app:Ogl_gui.Types.t_ogl_app) =
  trace __POS__;
    let app = Cocoa_ogl_app.create ogl_root_dir ogl_app in
  trace __POS__;
    Cocoa_ogl_app.run app


