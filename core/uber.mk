# Copyright (C) 2014-2017 UBER
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

###################
# Strict Aliasing #
###################
LOCAL_DISABLE_STRICT := \
	libpdfiumfpdfapi \
	mdnsd

STRICT_ALIASING_FLAGS := \
	-fstrict-aliasing \
	-Werror=strict-aliasing

STRICT_GCC_LEVEL := \
	-Wstrict-aliasing=3

STRICT_CLANG_LEVEL := \
	-Wstrict-aliasing=2

############
# GRAPHITE #
############

LOCAL_DISABLE_GRAPHITE :=

GRAPHITE_FLAGS := \
	-fgraphite \
	-fgraphite-identity \
	-floop-flatten \
	-floop-parallelize-all \
	-ftree-loop-linear \
	-floop-interchange \
	-floop-strip-mine \
	-floop-block

#########
# POLLY #
#########

# Polly flags for use with Clang
POLLY := -mllvm -polly \
	-mllvm -polly-parallel -lgomp \
	-mllvm -polly-ast-use-context \
	-mllvm -polly-vectorizer=stripmine \
	-mllvm -polly-opt-fusion=max \
	-mllvm -polly-opt-maximize-bands=yes \
	-mllvm -polly-run-dce \
	-mllvm -polly-position=after-loopopt \
	-mllvm -polly-run-inliner \
	-mllvm -polly-detect-keep-going \
	-mllvm -polly-opt-simplify-deps=no \
	-mllvm -polly-rtc-max-arrays-per-group=40

# Those are mostly Bluetooth modules
DISABLE_POLLY_O3 := \
	audio.a2dp.default \
	bdAddrLoader \
	bdt \
	bdtest \
	bluetooth.mapsapi \
	bluetooth.default \
	bluetooth.mapsapi \
	libbluetooth_jni \
	libbt% \
	libosi \
	memtest \
	net_bdtool \
	net_hci \
	net_test_btcore \
	net_test_device \
	net_test_osi \
	ositests \
	recovery

ifneq ($(filter marlin,$(TARGET_DEVICE)),)
DISABLE_POLLY_O3 += \
	libGLES_android
endif

# Disable modules that dont work with Polly. Split up by arch.
DISABLE_POLLY_arm :=  \
	libavcdec \
	libavcenc \
	libcrypto \
        libcrypto_static \
	libcryptfslollipop \
	libdng_sdk \
	libF77blas \
	libFFTEm \
	libFraunhoferAAC \
	libjni_filtershow \
	libjni_filtershow_filters \
	libjni_imageutil \
	libjni_snapcammosaic \
	libjpeg_static \
	libLLVM% \
	libmedia_jni \
	libmpeg2dec \
	libbnnmlowp \
	libopus \
	libpdfiumfpdfapi \
	libpdfiumfxge \
	libpdfiumjpeg \
	librsjni \
	libRSCpuRef \
	libscrypttwrp_static \
	libskia_static \
	libsonic \
	libstagefright% \
	libvpx \
	libwebp-decode \
	libwebp-encode \
	libwebrtc% \
	libyuv_static

DISABLE_POLLY_arm64 := \
	$(DISABLE_POLLY_arm) \
	libaudioutils \
	libscrypt_static \
	libsvoxpico

# Set DISABLE_POLLY based on arch
LOCAL_DISABLE_POLLY := \
  $(DISABLE_POLLY_$(TARGET_ARCH)) \
  $(DISABLE_POLLY_O3)

# We just don't want these flags
my_cflags := $(filter-out -O3 -O2 -Os -O1 -O0 -Og -Oz -Wall -Werror -g -Wextra -Weverything,$(my_cflags))
my_cppflags := $(filter-out -O3 -O2 -Os -O1 -O0 -Og -Oz -Wall -Werror -g -Wextra -Weverything,$(my_cppflags))
my_conlyflags := $(filter-out -O3 -O2 -Os -O1 -O0 -Og -Oz -Wall -Werror -g -Wextra -Weverything,$(my_conlyflags))

ifneq (1,$(words $(filter $(DISABLE_POLLY_O3),$(LOCAL_MODULE))))
  my_cflags += -O3
else
  my_cflags += -Os
endif

ifeq ($(my_clang), true)
  # Do not enable POLLY on libraries
  ifndef LOCAL_IS_HOST_MODULE
    # Enable POLLY if not blacklisted
    ifneq (1,$(words $(filter $(LOCAL_DISABLE_POLLY),$(LOCAL_MODULE))))
      # Enable POLLY only on clang
      ifneq ($(LOCAL_CLANG),false)
        my_cflags += $(POLLY) -Qunused-arguments -fuse-ld=gold
        my_ldflags += -fuse-ld=gold
      endif
    endif
  endif
endif

ifeq ($(LOCAL_CLANG),false)
  my_cflags += -Wno-unknown-warning
endif

ifeq ($(STRICT_ALIASING),true)
  # Remove the no-strict-aliasing flags
  my_cflags := $(filter-out -fno-strict-aliasing,$(my_cflags))
  ifneq (1,$(words $(filter $(LOCAL_DISABLE_STRICT),$(LOCAL_MODULE))))
    ifneq ($(LOCAL_CLANG),false)
      my_cflags += $(STRICT_ALIASING_FLAGS) $(STRICT_GLANG_LEVEL)
    else
      my_cflags += $(STRICT_ALIASING_FLAGS) $(STRICT_GCC_LEVEL)
    endif
  endif
endif

ifeq ($(GRAPHITE_OPTS),true)
  # Enable graphite only on GCC
  ifneq ($(LOCAL_CLANG),false)
    my_cflags += $(GRAPHITE_FLAGS)
  endif
endif
