package com.alexandre.splittrip.service;

import com.alexandre.splittrip.exception.ResourceNotFoundException;
import com.alexandre.splittrip.model.Member;
import com.alexandre.splittrip.model.Trip;
import com.alexandre.splittrip.repository.MemberRepository;
import com.alexandre.splittrip.repository.TripRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class TripService {

    private final TripRepository tripRepository;
    private final MemberRepository memberRepository;

    public TripService(TripRepository tripRepository, MemberRepository memberRepository) {
        this.tripRepository = tripRepository;
        this.memberRepository = memberRepository;
    }

    public Trip createTrip(String tripName) {
        Trip newTrip = new Trip();
        newTrip.setName(tripName);

        String generatedCode = generateRoomCode();
        newTrip.setRoomCode(generatedCode);

        return tripRepository.save(newTrip);

    }

    public Member joinTrip(String roomCode, String memberName) {

        Trip trip = tripRepository.findByRoomCode(roomCode)
                .orElseThrow(() -> new ResourceNotFoundException("Room with code " + roomCode + " not found!"));


        Member newMember = new Member();
        newMember.setName(memberName);
        newMember.setTrip(trip);

        return memberRepository.save(newMember);
    }


    private String generateRoomCode() {
        return UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }


    public Trip getTripByRoomCode(String roomCode) {
        return tripRepository.findByRoomCode(roomCode)
                .orElseThrow(() -> new ResourceNotFoundException("Viagem com o código " + roomCode + " não encontrada!"));
    }



}