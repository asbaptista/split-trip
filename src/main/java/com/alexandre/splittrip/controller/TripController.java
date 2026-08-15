package com.alexandre.splittrip.controller;

import com.alexandre.splittrip.dto.CreateTripRequest;
import com.alexandre.splittrip.dto.JoinTripRequest;
import com.alexandre.splittrip.model.Member;
import com.alexandre.splittrip.model.Trip;
import com.alexandre.splittrip.service.TripService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/trips")
public class TripController {

    private final TripService tripService;

    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    // Endpoint: POST /api/trips
    @PostMapping
    public ResponseEntity<Trip> createTrip(@RequestBody CreateTripRequest request) {
        Trip newTrip = tripService.createTrip(request.getTripName());
        // Devolvem o código HTTP 201 CREATED (boa prática REST para criação de recursos)
        return ResponseEntity.status(HttpStatus.CREATED).body(newTrip);
    }

    // Endpoint: POST /api/trips/join
    @PostMapping("/join")
    public ResponseEntity<Member> joinTrip(@RequestBody JoinTripRequest request) {
        Member newMember = tripService.joinTrip(request.getRoomCode(), request.getMemberName());
        return ResponseEntity.status(HttpStatus.CREATED).body(newMember);
    }
}