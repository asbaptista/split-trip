package com.alexandre.splittrip.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.alexandre.splittrip.model.Trip;
import java.util.Optional;

public interface TripRepository extends JpaRepository<Trip, Long> {
    Optional<Trip> findByRoomCode(String roomCode);
}