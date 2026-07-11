# 🕒 Basys 3 기반 디지털 시계/스톱워치 & 온습도·초음파 센서 통합 시스템 (UART + FIFO 제어 및 SystemVerilog 검증)

AMD Artix™-7 (Basys 3) FPGA 보드를 활용하여 **디지털 시계(Watch), 스톱워치(Stopwatch), DHT11 온습도 센서, HC-SR04 초음파 센서**를 통합 구동하는 SoC 설계 프로젝트입니다.  
동기식 FIFO 버퍼와 UART IP를 직접 설계하여 보드의 계측 데이터를 PC로 모니터링하고 PC 키보드 입력(ASCII)을 통해 시스템을 원격 제어할 수 있습니다. 또한, **SystemVerilog 기반 UVM-style Verification Environment**를 구축하여 모든 기능 블록의 시뮬레이션 및 검증을 완료하였습니다.

---

## 🛠️ 개발 환경 & 사용 기술

| 분류 | 항목 | 세부 사양 / 도구 |
| :--- | :--- | :--- |
| **Hardware** | FPGA Board | AMD Xilinx Basys 3 (Artix-7 XC7A35T-1CPG236C) |
| **Software** | IDE / Toolchain | Vivado Design Suite 2020.2 |
| | Text Editor | VS Code |
| **Language** | Design | Verilog HDL |
| | Verification | SystemVerilog |
| **Debugging** | H/W Debugger | Vivado Integrated Logic Analyzer (ILA) |
| | Simulation | Vivado Simulator |

---
## 👨‍💻 팀원 소개 및 역할

| 이름 | 담당 역할 |
| :--------: |:------------------------------------------------------ |
| **강동우** | SR센서 설계 및 검증, fnd_controller로의 datapath 통일  |
| **안정원** | DHT11센서 설계 및 검증, fnd_controller로의 datapath 통일 |
| **서어진** | UART+FIFO 설계 및 검증, PC 출력 확인 |
| **문태성** | 전체 시스템 통합 및 검증, 구조 단순화 |
---

## 📐 시스템 아키텍처 (System Architecture)

전체 시스템은 센서 계측 블록(DATA_TOP)과 시리얼 전송 및 원격 제어 블록(UART_TOP)으로 이원화되어 유기적으로 연동됩니다.

<img width="2960" height="1082" alt="image" src="https://github.com/user-attachments/assets/006fbbda-7c8f-4f18-a0dd-4dc5ab08dc04" />

---

## 🌟 핵심 기능 및 모드 설정 명세

## 1.1. 시스템 동작 모드 설정 (sw[1:0])
시스템의 전체 계측 기능 모드는 보드상의 슬라이드 스위치 `sw[1:0]`을 조합하여 결정됩니다.

| `sw[1:0]` 상태 | 동작 Mode | FND 출력 데이터 포맷 | PC 터미널 송신 데이터 예시 |
| :--- | :--- | :--- | :--- |
| `2'b00` | 디지털 시계 (Watch) | `시 : 분` 또는 `초 : 밀리초` | `time=23h59m` or `time=59s59ms` |
| `2'b01` | 스톱워치 (Stopwatch)| `시 : 분` 또는 `초 : 밀리초` | `stoptime=23h59m` or `stoptime=59s59ms` |
| `2'b10` | 초음파 센서 (SR04) | 계측된 실시간 물체 거리 ($cm$) | `distance=123.4cm` |
| `2'b11` | 온습도 센서 (DHT11)| 현재 환경 온도($^\circ C$) 및 습도($\%$) | `tmep=25.45C` or `humid=21.00` |

## 1.2. 시스템 세부 표시 및 연산 방향을 제어 (sw[2] ~ sw[5])

| 스위치 명 | 설정값 | 동작 및 기능 설명 |
| :--- | :---: | :--- |
| **sw[2]** (FND 자릿수 표시 전환) | `1` | 시계 및 스톱워치 모드 시 디스플레이에 **시(Hour) - 분(Minute)** 데이터 표시 |
| | `0` | 시계 및 스톱워치 모드 시 디스플레이에 **초(Second) - 밀리초(msec)** 데이터 표시 |
| **sw[3]** (스톱워치 방향) | `1` | 스톱워치를 **Down-counter (카운트 다운)** 모드로 가동 |
| | `0` | 스톱워치를 **Up-counter (카운트 업)** 모드로 가동 |
| **sw[4]** (시계 설정 모드 활성) | `1` | **시간 수정 모드 진입** (수정할 자리 펄스 대기 및 Up/Down 버튼 활성화) |
| | `0` | 일반 시계 시간 흐름 주행 상태 |
| **sw[5]** (DHT11 출력 데이터 선택) | `1` | FND 디스플레이에 계측된 **온도(Temperature)** 데이터 출력 |
| | `0` | FND 디스플레이에 계측된 **습도(Humidity)** 데이터 출력 |

## 1.3. PC 시리얼 키보드 원격 제어 (UART RX ASCII Key Map)
PC 터미널(예: ComPortMaster 등)에서 아스키 입력을 전송하면, 내부 `ascii_decoder`에서 FPGA의 특정 물리 버튼 제어 펄스로 매핑/변환하여 보드를 터치하지 않고 키보드로 원격 제어할 수 있습니다.

| 키보드 입력 키 | 디코딩 펄스 신호 | 시계 모드 (`sw[1:0]=2'b00`) | 스톱워치 모드 (`sw[1:0]=2'b01`) | 센서 모드 (`2'b10`, `2'b11`) |
| :---: | :--- | :--- | :--- | :--- |
| **`r`** | `o_btn_r` (물리 버튼 우측) | 시간 변경 모드 시 수정 자릿수 **우측 이동** | 스톱워치 **RUN / STOP** 제어 | 센서 계측 **START** |
| **`l`** | `o_btn_l` (물리 버튼 좌측) | 시간 변경 모드 시 수정 자릿수 **좌측 이동** | 스톱워치 **CLEAR (리셋)** | - |
| **`u`** | `o_btn_u` (물리 버튼 위쪽) | 선택된 자릿수 값 **1 증가 (UP)** | - | - |
| **`d`** | `o_btn_d` (물리 버튼 아래쪽) | 선택된 자릿수 값 **1 감소 (DOWN)** | - | - |
| **`s`** | `o_btn_s` | - | - | **UART 전송 지시** (계측 데이터 FIFO Push) |
| **`0` ~ `5`** | `o_btn_0` ~ `o_btn_5` | 수정할 특정 자릿수로 **다이렉트 이동** | - | - |

## 1.4. UART 데이터 송신 메시지 규격
시스템 데이터가 ASCII Sender를 통해 UART TX 핀으로 전달될 때, 각 제어 조건에 부합하는 문자열 형태로 가공되어 FIFO 버퍼에 적재됩니다.

| 타겟 모드 | i_sel (2진수) | i_sel_2[1] (h/m, s/ms) | i_sel_2[0] (temp/humid) | 전송 문자열 규격 (LF 포함) | 터미널 출력 예시 |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **시계 (sec/ms)** | `2'b00` | `0` | `?` | `time=XXsXXms\n` | `time=23s48ms` |
| **시계 (hour/min)** | `2'b00` | `1` | `?` | `time=XXhXXm\n` | `time=09h15m` |
| **스톱워치 (sec/ms)** | `2'b01` | `0` | `?` | `stop_time=XXsXXms\n` | `stop_time=12s04ms` |
| **스톱워치 (hour/min)** | `2'b01` | `1` | `?` | `stop_time=XXhXXm\n` | `stop_time=00h02m` |
| **초음파 거리 측정** | `2'b10` | `?` | `?` | `distance=XXXX.Xcm\n` | `distance=024.8cm` |
| **DHT11 온도 측정** | `2'b11` | `?` | `0` | `temp=XX.XXC\n` | `temp=24.50C` |
| **DHT11 습도 측정** | `2'b11` | `?` | `1` | `humid=XX.XX\n` | `humid=48.00` |

---

## 2. Sensor Control & Protocol Interface
### `sr04.v` (초음파 거리 측정 유닛)
<img width="2680" height="1308" alt="image" src="https://github.com/user-attachments/assets/a4331f62-88cc-46a9-ab4c-b6b8d67f0862" />
<img width="2762" height="1161" alt="image" src="https://github.com/user-attachments/assets/5ef2af74-b782-49dd-a8cc-a016f0ec4699" />


<img width="2968" height="1439" alt="image" src="https://github.com/user-attachments/assets/cd5f281a-5567-4c93-803f-0660d598942d" />
<img width="2960" height="1467" alt="image" src="https://github.com/user-attachments/assets/7cc86b19-fdb3-49fc-a472-f9a2b0b805c7" />

- 1us_tick 대신 5.8us_tick 사용하여 / 연산을 없애고 counter로 거리 계산하여 하드웨어 자원 소모 줄임.
---

### `dht11.v` (온습도 센서 제어 유닛)
<img width="1881" height="705" alt="image" src="https://github.com/user-attachments/assets/89ff3e4d-df52-4797-84e8-cf66afbb9ec4" />

- Bidirectional I/O Control: 단일 핀(`inout`)을 시분할하여 FPGA가 마스터로서 Start Signal(최소 18ms Low)을 드라이브한 후, 즉시 수신 모드(High-Z 플로팅)로 전환하는 삼상 버퍼(Tri-state Buffer) 로직 구현.
      
- Time-to-Data Decoding: 1us 단위의 정밀 타이머(`tick_gen_1us`)를 기반으로, 센서가 응답하는 하이 펄스의 유지 시간(26~28us: 데이터 '0' / 70us: 데이터 '1')을 계측하여 40-bit 데이터 스트림을 에러 없이 복원하는 FSM 설계.

<img width="2969" height="1135" alt="image" src="https://github.com/user-attachments/assets/511eab11-343b-4c16-9860-44db963aa3b7" />
<img width="2960" height="1465" alt="image" src="https://github.com/user-attachments/assets/fb2be38a-054a-46fb-8b23-31bae887c471" />

---

## 3. UART & FIFO
<img width="2947" height="1240" alt="image" src="https://github.com/user-attachments/assets/82d6e8c2-1d1d-4b60-8094-4c1d4f3441fc" />
<img width="2368" height="1175" alt="image" src="https://github.com/user-attachments/assets/86c5890a-f55b-437d-a546-b3af65e1f82c" />


* `uart_top.v` (`uart_rx.v` / `uart_tx.v`)
    * 9600 bps 통신의 안정성을 확보하기 위해 `baud_tick` 모듈에서 16배수 오버샘플링(153,600Hz Tick)을 수행하여 비트의 중앙값(Center Sampling)을 추출함으로써 노이즈 마진 극대화.

<img width="1682" height="1058" alt="image" src="https://github.com/user-attachments/assets/5385ff75-5eb6-4ae8-9364-0c14107bedab" />

* `ASCII_sender`

<img width="1137" height="410" alt="image" src="https://github.com/user-attachments/assets/68e3dc8e-d88c-47f5-aca2-22d1b28c9e43" />

* `fifo` (하드웨어 큐 버퍼)
    * Dual-Port Register Array: 16바이트 깊이(Depth 16, Width 8-bit)의 레지스터 어레이를 기반으로 순환 큐(Circular Queue) 구조의 FIFO 설계.
    * Status Flag Generation: Write Pointer와 Read Pointer의 상대적 위치 비교 및 동기 연산을 통해
      데이터 오버플로우를 방지하는 `o_full` 신호와 언더플로우를 방지하는 `o_empty` 상태 플래그 생성 유닛 탑재.

<img width="1139" height="776" alt="image" src="https://github.com/user-attachments/assets/9d59b19f-e268-43d7-9635-267abae0d530" />

* `pop_controller`
    * Baud Rate Synchronization: 100MHz 클럭 도메인에서 생성된 센서 및 시간 데이터(Binary)를 10진수 문자로 분리하고 ASCII 코드(`+ 8'h30`)로 인코딩하여 FIFO에 Push.
    * Tx Scheduling FSM: UART 송신 모듈의 상태(`tx_busy`, `tx_done`)를 핸드셰이킹(Handshaking)하여,
    * FIFO에 데이터가 존재하고 Tx가 Idle일 때만 1바이트씩 안전하게 빼내어(`Pop`) 송신 레이트를 제어하는 중재 로직 구현.

---

## 4. Core Datapath & Human Interface
* `control_unit.v` (중앙 제어 FSM)
    * `STOP`, `RUN`, `CLEAR`의 기본 동작 모드와 시계 세팅을 위한 상/하/좌/우 상태 머신 구성.
    * 6-bit 제어 버스(`i_mode`) 입력을 통해 로컬 물리 스위치와 UART 원격 명령의 원격 스위칭을 동시 수용.

<img width="1856" height="1043" alt="image" src="https://github.com/user-attachments/assets/76dd3d9d-2ad8-4ade-af13-78a4f255e639" />

* `fnd_controller.v` (Time Division Multiplexing 디스플레이)
    * 4자리의 FND 잔상 효과(Persistence of Vision)를 이용하기 위해 1kHz 클럭 분주기를 구현하고,
    * 상위 스위칭 데이터 선택 프로토콜에 따라 시계(`시:분` 또는 `초:밀리초`), 거리 데이터, 온습도 데이터를 선택적으로 라우팅하여 출력 최적화.
---

## 동작영상

https://github.com/user-attachments/assets/5c6d9d0d-d50e-4aad-8683-6ac38addce43

## 🛠️ 주요 트러블슈팅 (Troubleshooting & Debugging)

| 문제 현상 (Issue Description) | 발생 원인 (Root Cause) | 해결 방안 (Resolution) |
| :--- | :--- | :--- |
| **FND 특정 자릿수 상수로 멈춤** | `tick_counter`의 틱 신호 `o_tick`이 순차 회로(`always @(posedge clk)`) 내부와 조합 회로(`assign`)에서 동시 구동되어 Multi-Source 충돌 유발 | 순차 회로 내의 `o_tick <= 0;` 구문을 완전히 소거하고 조합 회로 assign 블록에서만 단일하게 구동하도록 정리하여 틱 클럭 인입 타이밍 복구 |
| **초음파 센서 거리값 측정 시 계속 누적** | 센서 내부 카운터 레지스터가 시스템 글로벌 리셋(`rst`)에만 초기화되어 동작 버튼을 새로 누를 때마다 거리가 계속 합산됨 | FSM이 초음파 트리거 송출 직전 단계인 `START` 상태로 천이할 때 작동 카운터를 동기식으로 초기화하는 `clear` 로직을 추가하여 문제 해결 |
| **FIFO DEPTH 변경 시 버퍼 중단 및 High-Z** | FIFO 깊이 크기 파라미터를 2의 제곱수($2^n$)가 아닌 임의의 값(예: 17, 21)으로 수정하여 주소 포인터의 롤오버 경계가 불일치함 | FIFO 주소 회전 설계의 특징을 감안하여 깊이 크기를 $2^n$ 단위인 **`16`으로 엄격히 고정**하고 자동 오버플로우가 돌게끔 수정하여 오작동 원천 차단 |
| **UART 16바이트 전송 완료 후 가비지 문자 추가**| `sender_top` 내부 상태 머신 제어 한계 에러로 인해 데이터 송출이 끝나는 마지막 시점에 FIFO PUSH 펄스가 1클럭 더 발생하여 이전 버퍼 문자 추가 송출 | ILA 장비를 통하여 PUSH 신호 주기를 확인 후, `!FIFO_FULL` 조건과 문자 인덱스 한계값 검사 타이밍의 동기화 캡처 에지를 1클럭 앞당겨 조기 차단 조치 |

---

# 🌟 SystemVerilog 검증 (SystemVerilog Testbenches)

---

## 👨‍💻 역할

| 이름 | 담당 역할 |
| :--------: |:------------------------------------------------------ |
| **강동우** | UART+FIFO SystemVerilog Scenario 작성 및 검증 |
| **서어진** | watch+stopwatch SystemVerilog Scenario 작성 및 검증 |

---

## UART & FIFO

### UART rx + ascii decoder
<img width="1525" height="1316" alt="image" src="https://github.com/user-attachments/assets/e45f6bc5-0372-49c0-990b-a005b72275f9" />

<img width="2704" height="789" alt="image" src="https://github.com/user-attachments/assets/cb38f605-eb14-4173-9b17-a12d87ded9a6" />

<img width="2936" height="1376" alt="image" src="https://github.com/user-attachments/assets/50f17f52-516d-44c5-a3fd-2154f6ad0279" />

---

### Sender + FIFO + Uart Tx 
<img width="2704" height="1493" alt="image" src="https://github.com/user-attachments/assets/26406b47-1f11-4937-97d4-6cc58250e0ef" />

---

#### sender
<img width="1298" height="1365" alt="image" src="https://github.com/user-attachments/assets/e6b4e05e-7256-4d45-96e8-1f369b93f0e9" />

<img width="2932" height="1258" alt="image" src="https://github.com/user-attachments/assets/70148620-78ef-4394-8b0d-02c0e44354d5" />

---

#### FIFO
<img width="1552" height="1337" alt="image" src="https://github.com/user-attachments/assets/2f8f35b9-2478-4dfd-8030-9c4c18e2e4f7" />
<img width="2421" height="1432" alt="image" src="https://github.com/user-attachments/assets/cac73db8-bc01-4262-aede-a32e43ebf3a6" />
<img width="2264" height="1427" alt="image" src="https://github.com/user-attachments/assets/47604b3e-093c-434a-b8fa-4c8bd8aa1e6a" />

---

#### Sender + FIFO + Uart Tx
<img width="1295" height="1364" alt="image" src="https://github.com/user-attachments/assets/0fb2177a-a121-43eb-8903-3fe52779859d" />
<img width="2494" height="1437" alt="image" src="https://github.com/user-attachments/assets/763cf99a-54b9-4127-8204-3ab5353d4247" />
<img width="2317" height="1504" alt="image" src="https://github.com/user-attachments/assets/babfbd75-5188-4224-bc92-0f18d7d27911" />

---

