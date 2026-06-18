# FPGA Integrated Control System: Watch, Environment Sensors & UART with FIFO Buffer

## 1. Project Overview
본 프로젝트는 AMD Artix-7 기반의 Basys 3 FPGA 보드를 핵심 타겟으로 하여, 디지털 시계/스톱워치 코어 로직에 
초음파 및 온습도 센서 제어 인터페이스를 통합한 임베디드 통합 관제 시스템(Integrated Control System) 설계입니다.

단순히 독립된 기능들을 나열하는 것에 그치지 않고, 각 모듈간의 데이터 버스를 통합하는 Data Routing 아키텍처를 설계했습니다. 
특히 시스템 클럭(100MHz)과 UART 직렬 통신(9600bps) 간의 극심한 클럭 도메인 차이로 발생하는 데이터 병목 및 유실 문제를 해결하기 위해, 
내부 하드웨어 FIFO(First-In, First-Out) 버퍼와 전용 Pop Controller를 직접 설계하여 데이터 무결성을 검증했습니다.

## 2. System Specification & Environment
| Category | Details |
| :--- | :--- |
| Target Hardware | AMD Artix-7 FPGA (Basys 3 Development Board) |
| EDA Tools | Xilinx Vivado 2020.2, VS Code |
| Hardware Language| Verilog HDL (Gate-level & Behavioral Modeling) |
| Peripherals | HC-SR04 (Ultrasonic), DHT11 (Temp/Humidity), 4-Digit 7-Segment (FND) |
| Interface Protocol| UART (9600 bps, 8-N-1 Configuration), 1-Wire Bidirectional Protocol |

## 3. Advanced Hardware Architecture & Module Details

전체 시스템은 모듈러 설계(Modular Design) 원칙에 따라 기능별로 완전히 격리된 하위 모듈로 설계되었으며, 최상위 모듈(`top.v`)에서 유기적으로 인터페이싱됩니다.

### 3.1. Sensor Control & Protocol Interface
* `dht11.v` (온습도 센서 제어 유닛)
<img width="2969" height="1135" alt="image" src="https://github.com/user-attachments/assets/b9efc5b1-8ad9-4e86-9fb4-033179cc8a76" />
<img width="2896" height="1462" alt="image" src="https://github.com/user-attachments/assets/f7c5e65c-4863-463c-ad32-2e1500861acd" />
    * Bidirectional I/O Control: 단일 핀(`inout`)을 시분할하여 FPGA가 마스터로서 Start Signal(최소 18ms Low)을 드라이브한 후,
      즉시 수신 모드(High-Z 플로팅)로 전환하는 삼상 버퍼(Tri-state Buffer) 로직 구현.
    * Time-to-Data Decoding: 1us 단위의 정밀 타이머(`tick_gen_1us`)를 기반으로, 센서가 응답하는 하이 펄스의
      유지 시간(26~28us: 데이터 '0' / 70us: 데이터 '1')을 계측하여 40-bit 데이터 스트림을 에러 없이 복원하는 FSM 설계.

* `sr04.v` (초음파 거리 측정 유닛)
<img width="2968" height="1429" alt="image" src="https://github.com/user-attachments/assets/bc9c247b-63d5-40d7-a34d-fb3e46bc553a" />
<img width="2758" height="1462" alt="image" src="https://github.com/user-attachments/assets/0fedebb2-b213-4ca9-99b4-57459ea6effe" />
    * Time of Flight (ToF) 계측: 센서 트리거 조건인 10us의 High 펄스를 정밀 인가한 후,
      돌아오는 Echo 신호의 High 유지 시간을 카운트하여 센서와 물체 간의 물리적 거리를 계산.

### 3.2. Async Data Buffering & Serial Communication
<img width="2947" height="1240" alt="image" src="https://github.com/user-attachments/assets/82d6e8c2-1d1d-4b60-8094-4c1d4f3441fc" />

* `fifo.v` (하드웨어 큐 버퍼)
    * Dual-Port Register Array: 16바이트 깊이(Depth 16, Width 8-bit)의 레지스터 어레이를 기반으로 순환 큐(Circular Queue) 구조의 FIFO 설계.
    * Status Flag Generation: Write Pointer와 Read Pointer의 상대적 위치 비교 및 동기 연산을 통해
      데이터 오버플로우를 방지하는 `o_full` 신호와 언더플로우를 방지하는 `o_empty` 상태 플래그 생성 유닛 탑재.
* `pop_controller.v` & `sender_top.v`
    * Baud Rate Synchronization: 100MHz 클럭 도메인에서 생성된 센서 및 시간 데이터(Binary)를 10진수 문자로 분리하고 ASCII 코드(`+ 8'h30`)로 인코딩하여 FIFO에 Push.
    * Tx Scheduling FSM: UART 송신 모듈의 상태(`tx_busy`, `tx_done`)를 핸드셰이킹(Handshaking)하여,
    * FIFO에 데이터가 존재하고 Tx가 Idle일 때만 1바이트씩 안전하게 빼내어(`Pop`) 송신 레이트를 제어하는 중재 로직 구현.
* `uart_top.v` (`uart_rx.v` / `uart_tx.v`)
    * 9600 bps 통신의 안정성을 확보하기 위해 `baud_tick` 모듈에서 16배수 오버샘플링(153,600Hz Tick)을 수행하여 비트의 중앙값(Center Sampling)을 추출함으로써 노이즈 마진 극대화.

### 3.3. Core Datapath & Human Interface
* `control_unit.v` (중앙 제어 FSM)
    * `STOP`, `RUN`, `CLEAR`의 기본 동작 모드와 시계 세팅을 위한 상/하/좌/우 상태 머신 구성.
    * 6-bit 제어 버스(`i_mode`) 입력을 통해 로컬 물리 스위치와 UART 원격 명령의 원격 스위칭을 동시 수용.
* `fnd_controller.v` (Time Division Multiplexing 디스플레이)
    * 4자리의 FND 잔상 효과(Persistence of Vision)를 이용하기 위해 1kHz 클럭 분주기를 구현하고,
    * 상위 스위칭 데이터 선택 프로토콜에 따라 시계(`시:분` 또는 `초:밀리초`), 거리 데이터, 온습도 데이터를 선택적으로 라우팅하여 출력 레디오 최적화.

## 전체 시스템 아키텍처 계층 구조 (Top-Down Block Diagram)
<img width="2950" height="956" alt="image" src="https://github.com/user-attachments/assets/64a76f93-2662-4a22-a898-f017b0fb298b" />

## 4. System Register & Control Mapping
보드의 스위치(`sw`) 설정에 따라 FND에 디스플레이되는 데이터와 UART를 통해 PC로 송신되는 데이터 패스가 동기화되어 매핑됩니다.

| `sw[1:0]` 상태 | 활성화 모드 (Mode) | FND 출력 데이터 포맷 | PC 터미널 송신 데이터 예시 |
| :--- | :--- | :--- | :--- |
| `2'b00` | 디지털 시계 (Watch) | `시 : 분` 또는 `초 : 밀리초` (sw[2] 전환) | `[TIME] 23:59:59` |
| `2'b01` | 스톱워치 (Stopwatch)| `분 : 초` 및 밀리초 단위 연산 | `[STW] 01:23:45` |
| `2'b10` | 초음파 센서 (SR04) | 계측된 실시간 물체 거리 ($cm$) | `[DIST] 15 cm` |
| `2'b11` | 온습도 센서 (DHT11)| 현재 환경 온도($^\circ C$) 및 습도($\%$) | `[ENV] T:26C H:45%` |

## 5. 동작 영상
<img width="1962" height="1104" alt="image" src="https://github.com/user-attachments/assets/8fbfc978-4a2c-4b87-88f3-981dc8071430" />


## 6. In-System Debugging & Trouble Shooting
본 프로젝트에서 가장 고도화된 하드웨어 디버깅 경험은 비동기 통신 간의 데이터 유실(Data Drop) 이슈를 칩 내부 레벨에서 분석하고 해결한 것입니다.

* 문제 정의 (Symptom): 센서 계측 결과 문자열을 UART를 통해 PC 터미널로 연속 전송 시, 특정 바이트가 유실되거나 깨지는 현상 발생. 
* 원인 분석 (Root Cause Analysis via ILA): 
    * Vivado의 내부 로직 분석기 코어인 ILA(Integrated Logic Analyzer)를 하드웨어에 설계 삽입하여 시뮬레이션으로 잡히지 않는 실제 타이밍 포착.
    * 분석 결과, 센서 데이터를 ASCII 문자열로 디코딩하여 전송 요청 신호(`tx_start`)를 주는 속도가 UART 송신부 회로가 1바이트를 실제로 라인에 밀어내는 전송 완료 속도(`tx_done`)보다 빨라,
    * 이전 데이터가 채 전송되기 전에 다음 데이터가 덮어씌워지는(Overwrite) 병목 타이밍 발견.
* 해결 방안 및 검증 (Resolution): 
    * 속도 차이를 완충하기 위해 전송 데이터를 일시 보관할 수 있는 8-bit 하드웨어 FIFO 버퍼를 설계 및 도입.
    * 버퍼의 상태를 감시하여 TX가 확실히 비어 있을(`Idle`) 때만 다음 데이터를 팝업해 주는 전용 헨드셰이킹 제어기(`pop_controller`)를 설계 구조에 추가.
    * 수정 후 ILA 시그널 디버깅을 재수행하여 `tx_start`와 `tx_busy`가 완벽하게 인터락킹(Interlocking)되어 데이터 유실율 0%의 안정적인 스트리밍이 이루어짐을 검증 완료.

## 7. Team & Presentation Information
* Project Team: 온디바이스 AI 시스템반도체 설계 1기 4조 (강동우, 문태성, 서어진, 안정현)
* Core Role: 시스템 통합 최상위 모듈 설계, UART 직렬 통신 컨트롤러 및 하드웨어 FIFO 버퍼 아키텍처 설계, ILA 기반 하드웨어 디버깅 및 트러블슈팅 주도.
