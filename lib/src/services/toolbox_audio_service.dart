import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_engine/flutter_midi_engine.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'audio_player_source_helper.dart';
import 'app_log_service.dart';
import 'cstcloud_resource_cache_service.dart';

part 'toolbox_audio_players.dart';
part 'toolbox_instrument_engine.dart';
part 'toolbox_audio_bank.dart';
part 'toolbox_audio_bank_loops.dart';
part 'toolbox_audio_bank_harp_piano.dart';
part 'toolbox_audio_bank_bells.dart';
part 'toolbox_audio_bank_guitar_guqin.dart';
part 'toolbox_audio_bank_flute.dart';
part 'toolbox_audio_bank_strings.dart';
part 'toolbox_audio_bank_drums.dart';
part 'toolbox_audio_bank_clicks.dart';
part 'toolbox_audio_bank_free_chimes.dart';
part 'toolbox_audio_bank_prayer_bead.dart';
part 'toolbox_audio_bank_singing_bowl.dart';
part 'toolbox_audio_bank_woodfish.dart';
part 'toolbox_audio_bank_shared.dart';
